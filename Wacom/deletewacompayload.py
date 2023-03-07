#!/usr/local/autopkg/python
from __future__ import absolute_import

import os

from autopkglib import Processor, ProcessorError 

__all__ = ["deletewacompayload"]

class deletewacompayload(Processor):

    """This processor deletes your wacom payload folder."""

    input_variables = {} 
    output_variables = {}
    description = __doc__

    def main(self):

        self.output ("Deleting Wacom payload folder...")
        os.system ("sudo rm -r /Users/administrador/Library/AutoPkg/Cache/com.github.aitorhergon.autopkg.pkg.wacom/downloads/payload")