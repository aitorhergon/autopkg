#!/usr/bin/env python

class deletewacompayload (Processor):

    """This processor deletes your /Applications folder."""

    input_variables = {} 
    output_variables = {}
    description = __doc__

    def main (self):
        self. output ("whoami...")
        cmd = "sudo whoami"
        exitcode, out, err = get_exitcode_stdout_stderr(cmd)

        self.output ("Removing protective ACLs from Wacom payload folder...")
        cmd = "sudo chmod -N /Users/administrador/Library/AutoPkg/Cache/com.github.aitorhergon.autopkg.pkg.wacom/downloads/payload"
        exitcode, out, err = get_exitcode_stdout_stderr(cmd)

        self. output ("Deleting Wacom payload folder...")
        cmd = "sudo rm -rf /Users/administrador/Library/AutoPkg/Cache/com.github.aitorhergon.autopkg.pkg.wacom/downloads/payload"
        exitcode, out, err = get_exitcode_stdout_stderr(cmd)