# sjx
Comparison of X-13ARIMA-SEATS and JDemetra+ seasonal adjustment methods on ABS data

# How to run

- Clone the repository: `https://github.com/a-s-russo/sjx.git`.
- Switch to the `pipeline` branch: `git switch pipeline`.
- Start an R session in the folder and run `renv::restore()`
   to install the project’s dependencies.
- Run the pipeline with `targets::tar_make()`.
- Checkout `sa_method_comparison.html` for the output.