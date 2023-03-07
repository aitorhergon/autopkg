#!/usr/local/autopkg/python
from __future__ import absolute_import

import os

from autopkglib import Processor, ProcessorError 

__all__ = ["deletewacompayload"]

class deletewacompayload(Processor):

    """This processor deletes your wacom payload folder."""

    input_variables = {
            "payload_path": {
            "required": True,
            "description": (),
        },
            "unpack_path": {
                "required": True,
                "description": (),
        },
        } 
    output_variables = {}
    description = __doc__

    def main(self):
        try:
            self.output ("Deleting Wacom payload folder...")
            os.system ("sudo rm -r {payload_path}")

            self.output ("Deleting Wacom unpack folder...")
            os.system ("sudo rm -r {unpack_path}")
        except Exception as err:
            raise ProcessorError(err)
        
if __name__ == "__main__":
    PROCESSOR = deletewacompayload()
    PROCESSOR.execute_shell()