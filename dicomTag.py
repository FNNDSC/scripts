#!/usr/bin/env python
#
# NAME
#
#        dicomTag.py
#
# DESCRIPTION
#
#       'dicomTag' reads an input DICOM file
#       and returns information about the tag
#       (i.e. meta) data.
#
# HISTORY
#
# 25 November 2015
# o Initial design and coding.
#

from __future__ import print_function

# System imports
import      os
import      sys
import      getpass
import      argparse
import      time
import      glob
import      numpy           as          np
from        random          import      randint
import      re
import      json

# System dependency imports
import     nibabel           as         nib
import     dicom
import     pylab
import     matplotlib.cm     as         cm

# Project specific imports
import     error
import     message           as msg
from       _common           import     systemMisc     as misc
from       _common._colors   import     Colors
from       _common           import     crun

class dicomTag(object):
    """
        dicomTag accepts a DICOM file as input, as well as list of tags and
        then returns in either HTML or JSON format the relevant header
        information.
    """

    _dictErr = {
        'inputDICOMFileFail'   : {
            'action'        : 'trying to read input DICOM file, ',
            'error'         : 'could not access/read file -- does it exist? Do you have permission?',
            'exitCode'      : 10},
        'inputTAGLISTFileFail': {
            'action'        : 'trying to read input <tagFileList>, ',
            'error'         : 'could not access/read file -- does it exist? Do you have permission?',
            'exitCode'      : 20
            }
    }

    def log(self, *args):
        '''
        get/set the internal pipeline log message object.

        Caller can further manipulate the log object with object-specific
        calls.
        '''
        if len(args):
            self._log = args[0]
        else:
            return self._log

    def name(self, *args):
        '''
        get/set the descriptive name text of this object.
        '''
        if len(args):
            self.__name = args[0]
        else:
            return self.__name

    def description(self, *args):
        '''
        Get / set internal object description.
        '''
        if len(args):
            self._str_desc = args[0]
        else:
            return self._str_desc

    def log(self): return self._log

    @staticmethod
    def urlify(astr, astr_join = '_'):
        # Remove all non-word characters (everything except numbers and letters)
        astr = re.sub(r"[^\w\s]", '', astr)

        # Replace all runs of whitespace with an underscore
        astr = re.sub(r"\s+", astr_join, astr)

        return astr

    def __init__(self, **kwargs):

        #
        # Object desc block
        #
        self._str_desc                  = ''
        self._log                       = msg.Message()
        self._log._b_syslog             = True
        self.__name                     = "dicomTag"

        # Directory and filenames
        self._str_workingDir            = ''
        self._str_inputFile             = ''
        self._str_outputFileStem        = ''
        self._str_outputFileType        = ''
        self._str_outputDir             = ''
        self._str_inputDir              = ''

        self._str_stdout                = ''
        self._str_stderr                = ''
        self._exitCode                  = 0

        # The actual data volume and slice
        # are numpy ndarrays
        self._dcm                       = None
        self._strRaw                    = ''
        self._l_tagRaw                  = []
        self._d_dcm                     = {}

        self._d_dicom                   = {}
        self._d_json                    = {}

        # Image conversion
        self._b_convertToImg            = False
        self._str_outputImageFile       = ''

        # A logger
        self._log                       = msg.Message()
        self._log.syslog(True)

        # Tags
        self._b_tagList                 = False
        self._b_tagFile                 = False
        self._str_tagList               = ''
        self._str_tagFile               = ''
        self._l_tag                     = []

        # Flags

        for key, value in kwargs.iteritems():
            if key == "inputFile":          self._str_inputFile         = value
            if key == "outputDir":          self._str_outputDir         = value
            if key == "outputFileStem":     self._str_outputFileStem    = value
            if key == "outputFileType":     self._str_outputFileType    = value
            if key == 'rawType':            self._str_rawType           = value
            if key == 'imageFile':
                self._str_outputImageFile   = value
                if len(self._str_outputImageFile):
                    self._b_convertToImg    = True
            if key == 'tagFile':
                self._str_tagFile           = value
                if len(self._str_tagFile):
                    self._b_tagFile         = True
            if key == 'tagList':
                self._str_tagList       = value
                if len(self._str_tagList):
                    self._b_tagList         = True

        if self._b_tagList:
            self._l_tag                 = self._str_tagList.split(',')

        if self._b_tagFile:
            with open(self._str_tagFile) as f:
                self._l_tag             =  [x.strip('\n') for x in f.readlines()]

        self._str_inputDir              = os.path.dirname(self._str_inputFile)
        if not len(self._str_inputDir): self._str_inputDir = '.'
        str_fileName, str_fileExtension  = os.path.splitext(self._str_outputFileStem)
        if len(self._str_outputFileType):
            str_fileExtension           = '.%s' % self._str_outputFileType

        if len(str_fileExtension) and not len(self._str_outputFileType):
            self._str_outputFileType    = str_fileExtension

        if not len(self._str_outputFileType) and not len(str_fileExtension):
            self._str_outputFileType    = '.html'

        self._str_outputFile            = '%s.%s'  %\
                                            (self._str_outputFileStem,
                                             self._str_outputFileType)

    def run(self):
        '''
        The main 'engine' of the class.
        '''
        self._dcm       = dicom.read_file(self._str_inputFile)
        self._strRaw    = str(self._dcm)
        self._l_tagRaw  = self._dcm.dir()
        self._d_dcm     = dict(self._dcm)

        for key in self._l_tagRaw:
            self._d_dicom[key]   = self._dcm.data_element(key)

        if self._b_tagFile or self._b_tagList:
            for tag in self._l_tag:
                print('%30s%s' % (tag + ': ', self._d_dicom[tag]))
        else:
            if self._str_rawType == 'dir':
                for tag in self._l_tagRaw:
                    print('%30s%s' % (tag + ': ', self._d_dicom[tag]))
            elif self._str_rawType   == 'raw':
                print(self._dcm)
            else:
                print('Specify either "raw" or "dir" for "-r" flag.')


        if self._b_convertToImg:
            self.img_create()

    def img_create(self):
        '''
        Create the output jpg of the file.
        :return:
        '''
        pylab.imshow(self._dcm.pixel_array, cmap=pylab.cm.bone)
        pylab.savefig(self._str_outputImageFile)

    def echo(self, *args):
        self._b_echoCmd         = True
        if len(args):
            self._b_echoCmd     = args[0]

    def echoStdOut(self, *args):
        self._b_echoStdOut      = True
        if len(args):
            self._b_echoStdOut  = args[0]

    def stdout(self):
        return self._str_stdout

    def stderr(self):
        return self._str_stderr

    def exitCode(self):
        return self._exitCode

    def echoStdErr(self, *args):
        self._b_echoStdErr      = True
        if len(args):
            self._b_echoStdErr  = args[0]

    def dontRun(self, *args):
        self._b_runCmd          = False
        if len(args):
            self._b_runCmd      = args[0]

    def workingDir(self, *args):
        if len(args):
            self._str_workingDir = args[0]
        else:
            return self._str_workingDir

class dicomTag_html(dicomTag):
    '''
    Sub class that generates an index.html page of the tags.
    '''
    def __init__(self, **kwargs):
        dicomTag.__init__(self, **kwargs)

    def run(self):
        '''
        Runs the DICOM header tag to index.html class.
        '''
        misc.mkdir(self._str_outputDir)
        f = open('%s/%s' % (self._str_outputDir, self._str_outputFile), 'w')

        dicomTag.run(self)
        htmlPage = '''
<!DOCTYPE html>
<html>
<head>
  <title>DCM tags: %s</title>
</head>
<body>
    <pre>
%s
    </pre>
</body>
</html> ''' % (self._str_inputFile, self._strRaw)

        print(htmlPage, file=f)


def synopsis(ab_shortOnly = False):
    scriptName = os.path.basename(sys.argv[0])
    shortSynopsis =  '''
    NAME

	    dicomTag.py - print a DICOM file header information

    SYNOPSIS

            %s                                     \\
                     -i|--input <inputFile>                 \\
                        [-F|--tagFile <tagFile>] |          \\
                        [-T|--tagList <tagList>] |          \\
                        [-r raw|dir]                        \\
                    [-I|--image <imageFile>]                \\
                    [-d|--outputDir <outputDir>]            \\
                    [-o|--output <outputFileStem>]          \\
                    [-t|--outputFileType <outputFileType>]  \\
                    [-x|--man]				    \\
		    [-y|--synopsis]

    BRIEF EXAMPLE

	    dicomTag.py -l tagList.txt -i slice.dcm

    ''' % scriptName

    description =  '''
    DESCRIPTION

        `%s' prints the header information of a passed DICOM file.
        By default, all tags in the DICOM file are printed in a formatted
        manner.

        Optionally, the tag list can be constrained either by passing a
        <tagFile> containing a line-by-line list of tags to query, or
        by passing a comma separated list of tags directly.

    ARGS

        -i|--inputFile <inputFile>
        Input DICOM file to parse.

        NOTE: If neither -F nor -T are specified, a '-r raw' is
        assumed.

        -r raw|dir

        -F|--tagFile <tagFile>
        Read the tags, one-per-line in <tagFile>, and print the
        corresponding tag information in the DICOM <inputFile>.

        -T|--tagList <tagList>
        Read the list of comma-separated tags in <tagList>, and print the
        corresponding tag information parsed from the DICOM <inputFile>.

        -I|--image <imageFile>
        If specified, also convert the <inputFile> to <imageFile>.

        [-d|--outputDir <outputDir>]
        The directory to contain the output tag list.

        -o|--outputFileStem <outputFileStem>
        The output file stem to store data. If this is specified
        with an extension, this extension will be used to specify the
        output file type.

        [-t|--outputFileType <outputFileType>]
        The output file type. If different to <outputFileStem> extension,
        will override extension in favour of <outputFileType>. This can be
        either 'json' or 'html'.

        [-x|--man]
        Show full help.

        [-y|--synopsis]
        Show brief help.

    EXAMPLES

        o See https://github.com/FNNDSC/scripts/blob/master/dicomTag.py for more help and source.

    ''' % (scriptName)
    if ab_shortOnly:
        return shortSynopsis
    else:
        return shortSynopsis + description

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description="'dicomTag.py' prints the DICOM header information of a given input DICOM file.")
    parser.add_argument("-i", "--inputFile",
                        help="input file",
                        dest='inputFile')
    parser.add_argument("-F", "--tagFile",
                        help="file containing tags to parse",
                        dest='tagFile',
                        default='')
    parser.add_argument("-T", "--tagList",
                        help="comma-separated tag list",
                        dest='tagList',
                        default='')
    parser.add_argument("-r",
                        help="display raw tags",
                        dest='rawType',
                        default='raw')
    parser.add_argument("-I", "--imageFile",
                        help="image file to convert DICOM input",
                        dest='imageFile',
                        default='')
    parser.add_argument("-o", "--outputFileStem",
                        help="output file",
                        default="",
                        dest='outputFileStem')
    parser.add_argument("-d", "--outputDir",
                        help="output image directory",
                        dest='outputDir',
                        default='.')
    parser.add_argument("-t", "--outputFileType",
                        help="output image type",
                        dest='outputFileType',
                        default='')
    parser.add_argument("--printElapsedTime",
                        help="print program run time",
                        dest='printElapsedTime',
                        action='store_true',
                        default=False)
    parser.add_argument("-x", "--man",
                        help="man",
                        dest='man',
                        action='store_true',
                        default=False)
    parser.add_argument("-y", "--synopsis",
                        help="short synopsis",
                        dest='synopsis',
                        action='store_true',
                        default=False)
    args = parser.parse_args()

    if args.man or args.synopsis:
        if args.man:
            str_help     = synopsis(False)
        else:
            str_help     = synopsis(True)
        print(str_help)
        sys.exit(1)

    str_outputFileStem, str_outputFileExtension     = os.path.splitext(args.outputFileStem)
    if len(str_outputFileExtension):
        str_outputFileExtension = str_outputFileExtension.split('.')[1]
    try:
        str_inputFileStem,  str_inputFileExtension      = os.path.splitext(args.inputFile)
    except:
        print(synopsis(False))
        sys.exit(1)

    if not len(args.outputFileType) and len(str_outputFileExtension):
        args.outputFileType = str_outputFileExtension

    if len(str_outputFileExtension):
        args.outputFileStem = str_outputFileStem

    b_htmlExt           =  str_outputFileExtension   == 'html'
    b_jsonExt           =  str_outputFileExtension   == 'json'

    if not b_htmlExt:
        C_dicomTag     = dicomTag(
                                inputFile           = args.inputFile,
                                outputDir           = args.outputDir,
                                outputFileStem      = args.outputFileStem,
                                outputFileType      = args.outputFileType,
                                tagFile             = args.tagFile,
                                tagList             = args.tagList,
                                rawType             = args.rawType,
                                imageFile           = args.imageFile
                            )

    if b_htmlExt:
        C_dicomTag   = dicomTag_html(
                                inputFile           = args.inputFile,
                                outputDir           = args.outputDir,
                                outputFileStem      = args.outputFileStem,
                                outputFileType      = args.outputFileType,
                                tagFile             = args.tagFile,
                                tagList             = args.tagList,
                                imageFile           = args.imageFile
                             )


    # And now run it!
    misc.tic()
    C_dicomTag.run()
    if args.printElapsedTime: print("Elapsed time = %f seconds" % misc.toc())
    sys.exit(0)
