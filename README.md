# sjx
Comparison of X-13ARIMA-SEATS and JDemetra+ seasonal adjustment methods on ABS data

# How to run

- Clone the repository: `git clone https://github.com/a-s-russo/sjx.git`.
- Switch to the `pipeline` branch: `git switch pipeline`.
- Start an R session in the folder and use `renv::restore()` (and `renv::status()` as necessary) to install the project’s dependencies.
- Run the pipeline with `targets::tar_make()`.
- Inspect the file `sa_method_comparison.html` for the output.