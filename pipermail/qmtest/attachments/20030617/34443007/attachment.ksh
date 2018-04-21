#
# Copyright (C) 2003 Stefan Seefeld <seefeld@sympatico.ca>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
# MA 02139, USA.

import qm
import qm.fields
from qm.executable import RedirectedExecutable
from qm.test.test import Test
from qm.test.result import Result
from qm.attachment import Attachment, FileAttachmentStore
from qm.test.database import ResourceDescriptor, TestDescriptor, NoSuchTestError
from qm.test.file_database import FileDatabase
from qm.test.suite import Suite
import os
import string
import sys

class SimpleTest(Test):
    """Check a program's exit code.
    """


    arguments = [qm.fields.AttachmentField(name="srcdir",
                                           title="Source Directory",
                                           description="""The source directory."""),
                 qm.fields.AttachmentField(name="src",
                                           title="Source File",
                                           description="""The source file."""),
                 qm.fields.AttachmentField(name="CXX",
                                           title="the compiler command",
                                           description="""The compiler command."""),
                 qm.fields.AttachmentField(name="CPPFLAGS",
                                           title="preprocessor flags",
                                           description="""The preprocessor flags."""),
                 qm.fields.AttachmentField(name="CXXFLAGS",
                                           title="compiler flags",
                                           description="""The compiler flags."""),
                 qm.fields.AttachmentField(name="LDFLAGS",
                                           title="linker flags",
                                           description="""The linker flags."""),
                 qm.fields.AttachmentField(name="LIBS",
                                           title="libs",
                                           description="""The libs to link with.""")]

    def GetId(self):

        return self.src.GetFileName()[:-3]

    def _Compile(self, context, result):

        src = os.path.join(self.srcdir, self.src)
        obj = os.path.splitext(self.src)[0]
        if not os.path.isdir(os.path.dirname(obj)):
            os.makedirs(os.path.dirname(obj))

        command = '%s %s %s %s -o %s %s %s'%(self.CXX,
                                             self.CPPFLAGS, self.CXXFLAGS,
                                             self.LDFLAGS, obj, self.LIBS, src)
        compiler = RedirectedExecutable()
        status = compiler.Run(string.split(command))
        if os.WIFEXITED(status) and os.WEXITSTATUS(status) == 0:
            return obj
        else:
            result.Fail('compilation failed',
                        {'mytest.error': compiler.stderr,
                         'mytest.command': command})
            return None
        
    def Run(self, context, result):

        executable = self._Compile(context, result)
        if executable:
            test = RedirectedExecutable()
            status = test.Run([executable])
            if not os.WIFEXITED(status) or not os.WEXITSTATUS(status) == 0:
                result.Fail('program exit value : %i'%os.WEXITSTATUS(status))

class OutputTest(SimpleTest):
    """Check a program's output and exit code.
    """

    arguments = [qm.fields.AttachmentField(name="output",
                                           title="the expected output",
                                           description="""The expected output.""")]

    def Run(self, context, result):

        executable = self._Compile(context, result)
        if executable:
            test = RedirectedExecutable()
            status = test.Run([executable])
            if not os.WIFEXITED(status) or not os.WEXITSTATUS(status) == 0:
                outcome = Result.FAIL
                result.Fail('program exit value : %i'%os.WEXITSTATUS(status))

            else:
                expected = self.output
                if expected and not test.stdout:
                    result.Fail('program did not generate output')
                elif expected and not expected == test.stdout:
                    expected = '\'%s\''%(expected)
                    output = '\'%s\''%(test.stdout)
                    result.Fail('incorrect output',
                                {'mytest.expected': expected,
                                 'mytest.output': output})
        
class Database(FileDatabase):
    
    arguments = [qm.fields.TextField(name = "srcdir",
                                     title = "Source Directory",
                                     description ="""The root of the test source directory."""),
                 qm.fields.TextField(name = "label_class",
                                     default_value = "file_label.FileLabel",
                                     computed = "true"),
                 qm.fields.BooleanField(name = "modifiable",
                                        default_value = "false",
                                        computed = "true")]

    def __init__(self, path, arguments):
        
        # Initialize the base class.
        FileDatabase.__init__(self, path, arguments)
        # Create an attachment store.
        self.__store = FileAttachmentStore(self)

    def GetRoot(self):
        return self.srcdir

    def GetAttachmentStore(self):
        return self.__store

    def GetSuite(self, id):
        """get information about this suite from the local 'qmtest.py' file"""
        path = ''
        if id:
            path = apply(os.path.join, string.split(id, '.'))
        tests = []
        suites = []
        config = os.path.join(path, 'qmtest.py')
        if (os.path.isfile(config)):
            scope = {}
            execfile(config, scope)
            if scope.has_key('tests'):
                tests = map(lambda x:string.join([id, x], '.'), scope['tests'].keys())
            if scope.has_key('suites'):
                if not id:
                    suites = scope['suites']
                else:
                    suites = map(lambda x:string.join([id, x], '.'), scope['suites'])
        return Suite(self, id, implicit = 1, test_ids = tests, suite_ids = suites)

    def GetTest(self, id):
        path = apply(os.path.join, string.split(id, '.'))
        dirname = os.path.dirname(path)
        basename = os.path.basename(path)
        path = os.path.join(self.GetRoot(), path)
        makefile = os.path.join(dirname, 'qmtest.py')
        if (os.path.isfile(makefile)):
            scope = {}
            scope['CXX'] = 'c++'
            scope['CPPFLAGS'] = 'CPPFLAGS'
            scope['CXXFLAGS'] = 'CXXFLAGS'
            scope['LDFLAGS'] = 'LDFLAGS'
            scope['LIBS'] = 'LIBS'
            execfile(makefile, scope)
            parameters = {}
            parameters['CXX'] = scope['CXX']
            parameters['CPPFLAGS'] = scope['CPPFLAGS']
            parameters['CXXFLAGS'] = scope['CXXFLAGS']
            parameters['LDFLAGS'] = scope['LDFLAGS']
            parameters['LIBS'] = scope['LIBS']

            if scope.has_key('tests'):
                tests = scope['tests']
                if tests.has_key(basename):
                    
                    test_info = tests[basename]
                    if test_info.has_key('src'):
                        src = os.path.join(dirname, test_info['src'])
                        parameters['src'] = src
                    if test_info.has_key('output'):
                        parameters['output'] = output

                    parameters['srcdir'] = self.GetRoot()
                    descriptor = TestDescriptor(self, id,
                                                test_info['type'],
                                                parameters)
                    return descriptor
            raise NoSuchTestError(id)
        
