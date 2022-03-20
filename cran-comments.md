## R CMD check results
There were no ERRORs or WARNINGs.

There was 1 NOTE:

* Found the following calls to attach():
  File 'funspotr/R/spot-funs.R':
   attach(env, name = env_nm)
  See section 'Good practice' in '?attach'.

The function that uses `attach()` is only called within the function `call_r_list_functions_explicit()` which runs within a separate R process (via `callr::r()`) so it does not modify the functions attached in the users current environment. The purpose of using `attach()` is to add explicit calls of functions to the search space (i.e. `pkg::foo()`) to the search space without adding all functions in a package to the search space.
