# .Rprofile for DTA301 R Project
local({
  lib_local <- file.path(getwd(), ".r_lib")
  if (dir.exists(lib_local)) {
    .libPaths(unique(c(lib_local, .libPaths())))
  }
})
