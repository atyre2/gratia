#' Plot estimated smooths from a fitted GAM
#'
#' Plots estimated smooths from a fitted GAM model in a similar way to
#' `mgcv::plot.gam()` but instead of using base graphics, [ggplot2::ggplot()]
#' is used instead.
#'
#' @param object a fitted GAM, the result of a call to [mgcv::gam()].
#' @param data a optional data frame that may or may not be used? FIXME!
#' @param parametric logical; plot parametric terms also? Default is `TRUE`,
#'   only if `select` is `NULL`. If `select` is used, `parametric` is set to
#'   `FALSE` unless the user specifically sets `parametric = TRUE`.
#' @param select character, logical, or numeric; which smooths to plot. If
#'   `NULL`, the default, then all model smooths are drawn. Numeric `select`
#'   indexes the smooths in the order they are specified in the formula and
#'   stored in `object`. Character `select` matches the labels for smooths
#'   as shown for example in the output from `summary(object)`. Logical
#'   `select` operates as per numeric `select` in the order that smooths are
#'   stored.
#' @param residuals logical; should partial residuals for a smooth be drawn?
#'   Ignored for anything but a simple univariate smooth.
#' @param scales character; should all univariate smooths be plotted with the
#'   same y-axis scale? The default, `scales = "fixed"`, ensures this is done.
#'   If `scales = "free"` each univariate smooth has its own y-axis scale.
#'   Currently does not affect the y-axis scale of plots of the parametric
#'   terms.
#' @param constant numeric; a constant to add to the estimated values of the
#'   smooth. `constant`, if supplied, will be added to the estimated value
#'   before the confidence band is computed.
#' @param fun function; a function that will be applied to the estimated values
#'   and confidence interval before plotting. Can be a function or the name of a
#'   function. Function `fun` will be applied after adding any `constant`, if
#'   provided.
#' @param ci_level numeric between 0 and 1; the coverage of credible interval.
#' @param rug logical; draw a rug plot at the botom of each plot?
#' @param contour logical; should contours be draw on the plot using
#'   [ggplot2::geom_contour()].
#' @param contour_col colour specification for contour lines.
#' @param n_contour numeric; the number of contour bins. Will result in
#'   `n_contour - 1` contour lines being drawn. See [ggplot2::geom_contour()].
#' @param partial_match logical; should smooths be selected by partial matches
#'   with `select`? If `TRUE`, `select` can only be a single string to match
#'   against.
#' @param discrete_colour,continuous_colour,continuous_fill suitable scales
#'   for the types of data.
#' @param ncol,nrow numeric; the numbers of rows and columns over which to
#'   spread the plots
#' @param guides character; one of `"keep"` (the default), `"collect"`, or
#'   `"auto"`. Passed to [patchwork::plot_layout()]
#' @param ... additional arguments passed to [patchwork::wrap_plots()].
#'
#' @inheritParams evaluate_smooth
#'
#' @note Internally, plots of each smooth are created using [ggplot2::ggplot()]
#'   and composed into a single plot using [patchwork::wrap_plots()]. As a result,
#'   it is not possible to use `+` to add to the plots in the way one might
#'   typically work with `ggplot()` plots.
#'
#' @return The object returned is created by [patchwork::wrap_plots()].
#'
#' @author Gavin L. Simpson
#'
#' @importFrom ggplot2 scale_colour_discrete scale_colour_continuous
#'   scale_fill_distiller
#' @importFrom patchwork wrap_plots
#' @importFrom dplyr mutate rowwise %>% ungroup left_join summarise group_split
#' @importFrom purrr pluck
#' @importFrom rlang expr_label
#' @export
#'
#' @examples
#' load_mgcv()
#'
#' df1 <- data_sim("eg1", n = 400, dist = "normal", scale = 2, seed = 2)
#' m1 <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = df1, method = "REML")
#'
#' draw(m1)
#'
#' # can add partial residuals
#' draw(m1, residuals = TRUE)
#'
#' df2 <- data_sim(2, n = 1000, dist = "normal", scale = 1, seed = 2)
#' m2 <- gam(y ~ s(x, z, k = 40), data = df2, method = "REML")
#' draw(m2, contour = FALSE)
#'
#' # change the number of contours drawn and the fill scale used for
#' # the surface
#' draw(m2, n_contour = 5,
#'      continuous_fill = ggplot2::scale_fill_distiller(palette = "Spectral",
#'                                                      type = "div"))
`draw.gam` <- function(object,
                       data = NULL,
                       parametric = NULL,
                       select = NULL,
                       residuals = FALSE,
                       scales = c("free", "fixed"),
                       ci_level = 0.95,
                       n = 100,
                       unconditional = FALSE,
                       overall_uncertainty = TRUE,
                       constant = NULL,
                       fun = NULL,
                       dist = 0.1,
                       rug = TRUE,
                       contour = TRUE,
                       contour_col = "black",
                       n_contour = NULL,
                       partial_match = FALSE,
                       discrete_colour = NULL,
                       continuous_colour = NULL,
                       continuous_fill = NULL,
                       ncol = NULL, nrow = NULL,
                       guides = "keep",
                       ...) {
    model_name <- expr_label(substitute(object))
    # fixed or free?
    scales <- match.arg(scales)

    # fix up default scales
    if (is.null(discrete_colour)) {
        discrete_colour <- scale_colour_discrete()
    }
    if (is.null(continuous_colour)) {
        continuous_colour <- scale_colour_continuous()
    }
    if (is.null(continuous_fill)) {
        continuous_fill <- scale_fill_distiller(palette = "RdBu", type = "div")
    }

    # if not using select, set parametric TRUE if not set to FALSE
    if (!is.null(select)) {
        if (is.null(parametric)) {
            parametric <- FALSE
        }
    } else {
        if (is.null(parametric)) {
            parametric <- TRUE
        }
    }

    S <- smooths(object) # vector of smooth labels - "s(x)"

    # select smooths
    select <-
        check_user_select_smooths(smooths = S, select = select,
                                  partial_match = partial_match,
                                  model_name = expr_label(substitute(object)))

    # evaluate all requested smooths
    sm_eval <- smooth_estimates(object,
                                smooth = S[select],
                                n = n,
                                data = data,
                                unconditional = unconditional,
                                overall_uncertainty = overall_uncertainty,
                                dist = dist,
                                unnest = FALSE)

    # =====> Start Here in continuing fixes
    # --> if we unnest = FALSE above then we can't add a confint to the entire
    #     object in one go. So we'll need to add it when we compute the axis
    #     limits for fixed scales, plot the smooth, add rug, partial resids etc
    # --> doing all this will be easier now as we have 1 row per smooth in
    #     sm_eval

    # add confidence interval
    sm_eval <- sm_eval %>%
      rowwise() %>%
      mutate(data = list(add_confint(.data$data, coverage = ci_level))) %>%
      ungroup()

    # Take the range of the smooths & their confidence intervals now
    # before we put rug and residuals on
    sm_rng <- sm_eval %>%
        rowwise() %>%
        summarise(rng = range(c(data$est, data$lower_ci, data$upper_ci))) %>%
        pluck("rng")

    # Add partial residuals if requested - by default they are
    # At the end of this, sm_eval will have a new list column containing the
    # partial residuals, `partial_residual`
    p_resids_rng <- NULL
    if (isTRUE(residuals)) {
        if (is.null(residuals(object)) || is.null(weights(object))) {
            residuals <- FALSE
        } else {
            # get residuals in a suitable format
            p_resids <- nested_partial_residuals(object, terms = S[select])

            # compute the range of residuals for each smooth
            p_resids_rng <- p_resids %>%
                rowwise() %>%
                summarise(rng =
                          range(.data$partial_residual$partial_residual)) %>%
                pluck("rng")

            # merge with the evaluated smooth
            sm_eval <- left_join(sm_eval, p_resids, by = "smooth")
        }
    }

    # add rug data?
    if (isTRUE(rug)) {
        # get rug data in a suitable format
        rug_data <- nested_rug_values(object, terms = S[select])

        # merge with the evaluated smooth
        sm_eval <- left_join(sm_eval, rug_data, by = "smooth")
    }

    # need to figure out scales if "fixed"
    ylims <- NULL
    if (isTRUE(identical(scales, "fixed"))) {
        ylims <- range(sm_rng, p_resids_rng)
    }

    sm_l <- group_split(sm_eval, .data$smooth)

    sm_plts <- map(sm_l,
                   draw_smooth_estimates,
                   constant = constant,
                   fun = fun,
                   contour = contour,
                   contour_col = contour_col,
                   n_contour = n_contour,
                   partial_match = partial_match,
                   discrete_colour = discrete_colour,
                   continuous_colour = continuous_colour,
                   continuous_fill = continuous_fill,
                   ylim = ylims)

    ## return
    n_plots <- length(sm_plts)
    if (is.null(ncol) && is.null(nrow)) {
        ncol <- ceiling(sqrt(n_plots))
        nrow <- ceiling(n_plots / ncol)
    }
    wrap_plots(sm_plts, byrow = TRUE, ncol = ncol, nrow = nrow,
               guides = guides, ...)
    wrap_plots(sm_plts)
}
