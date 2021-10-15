
# encoding: utf-8
'''
@author:     Bruno Duarte Gouveia
        
@copyright:  2012 organization_name. All rights reserved.
        
@contact:    bgouveia@gmail.com
@deffield    updated: Updated
'''

import sys
import os
import struct
import numpy as np


from argparse import ArgumentParser
from argparse import RawDescriptionHelpFormatter

__all__ = []
__version__ = 0.1
__date__ = '2012-11-18'
__updated__ = '2012-11-18'

DEBUG = 1
TESTRUN = 0
PROFILE = 0

class CLIError(Exception):
    '''Generic exception to raise and log different fatal errors.'''
    def __init__(self, msg):
        super(CLIError).__init__(type(self))
        self.msg = "E: %s" % msg
    def __str__(self):
        return self.msg
    def __unicode__(self):
        return self.msg
    
def parsefile(filename,wordsize):

    dump=[]
    read_data=None;
    with open (filename,'rb') as inputfile:
        read_data = np.fromfile(inputfile,dtype=np.uint8)
    
    wordsizeinbytes=wordsize/8;
    wordcounter=0
    count=0
    tempstring=""
    for byte in read_data:
        s=hex(byte)[2:]
        if len(s) % 2 != 0 :
            s='0'+s
        tempstring+=s
        count=(count+1)%wordsizeinbytes
        
        if count==0:
            dump.append(tempstring)
            tempstring=""
            wordcounter+=1
    return [dump,wordcounter]

def writefile(filename,wordsize,data):
    
    f=open(filename,"w")
    
    f.write("WIDTH=")
    f.write(str(wordsize))
    f.write(";\n")
    f.write("DEPTH=")
    f.write(str(len(data)))
    f.write(";\n\n")
    
    f.write("ADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n")
    
    for i in range(0,len(data)):
        f.write("\t")
        f.write(hex(i)[2:])
        f.write("   :   ")
        f.write(data[i])
        f.write(";\n")
    
    f.write("END;\n")
    
    

def main(argv=None): # IGNORE:C0111
    '''Command line options.'''
    
    if argv is None:
        argv = sys.argv
    else:
        sys.argv.extend(argv)

    program_name = os.path.basename(sys.argv[0])
    program_version = "v%s" % __version__
    program_build_date = str(__updated__)
    program_version_message = '%%(prog)s %s (%s)' % (program_version, program_build_date)
    program_shortdesc = __import__('__main__').__doc__.split("\n")[1]
    program_license = '''%s
  Created by Bruno Gouveia on %s.
  Copyright 2012 organization_name. All rights reserved.
  
  Licensed under the Apache License 2.0
  http://www.apache.org/licenses/LICENSE-2.0
  
  Distributed on an "AS IS" basis without warranties
  or conditions of any kind, either express or implied.
USAGE
''' % (program_shortdesc, str(__date__))

    try:
        # Setup argument parser
        parser = ArgumentParser(description=program_license, formatter_class=RawDescriptionHelpFormatter)
        parser.add_argument(dest="inputfile", help="path to input file  [default: %(default)s]", metavar="inputfile")
        parser.add_argument(dest="outputfile", help="path to output file  [default: %(default)s]", metavar="outputfile")
        parser.add_argument(dest="wordsize", help="size of wordsize  [default: %(default)s]", metavar="wordsize", nargs='?',default=8)
        
        # Process arguments
        args = parser.parse_args()
        
        inputfile=args.inputfile
        outputfile=args.outputfile
        wordsize=int(args.wordsize)
        
        print "input:" , inputfile
        print "output:" , outputfile
        print "wordsize:" , wordsize
            
        result=parsefile(inputfile,wordsize)
        writefile(outputfile,wordsize,result[0])       
        return 0
    except KeyboardInterrupt:
        ### handle keyboard interrupt ###
        return 0
    except Exception, e:
        if DEBUG or TESTRUN:
            raise(e)
        indent = len(program_name) * " "
        sys.stderr.write(program_name + ": " + repr(e) + "\n")
        sys.stderr.write(indent + "  for help use --help")
        return 2

if __name__ == "__main__":
    sys.exit(main())
