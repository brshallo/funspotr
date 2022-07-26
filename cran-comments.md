## R CMD check results

There were no ERRORs or WARNINGs.

There was 1 NOTE:

* Found the following calls to attach():
  File 'funspotr/R/spot-funs.R':
   attach(env, name = env_nm)
  See section 'Good practice' in '?attach'.

The function (`funspotr:::attach_pkg_fun()` / `funspotr:::try_attach_pkg_fun()`) that uses `attach()` is only called within the function `funspotr:::call_r_list_functions_explicit()` which runs it within a separate R process (via `callr::r()`) hence the use of `attach()` here does not modify the search space of the *user's* current environment. The purpose of using `attach()` is to add explicit calls of specific functions to the search space of the ('callr' generated) R process (without adding all functions in a package). For example, when a file contains `pkg::foo()` only that function should be added to the ('callr' created) search space (not all functions in `pkg`). This functionality underlies how `funspotr::spot_funs()` identifies explicit `pkg::fun()` calls.
