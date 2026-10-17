# Later --path entries take precedence, so stubs/ comes after the real modules it shadows
switch("path", "$projectDir/../src/plat")
switch("path", "$projectDir/stubs")
switch("path", "$projectDir/../deps/arm_cores")
switch("path", "$projectDir/../deps/RTT")
switch("path", "$projectDir/../src")
switch("path", "$projectDir/../src/krnl_impl")
switch("path", "$projectDir/../src/krnl_intf")
switch("define", "domain=test")
# Sibling imports (e.g. plat/vectortable's `import plat`) bypass --path; patch them to the stub
patchFile("krnl", "plat", "$projectDir/stubs/plat")
