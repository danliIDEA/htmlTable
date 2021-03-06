#' A merges lines while preserving the line break for html/LaTeX
#'
#' This function helps you to do a multiline
#' table header in both html and in LaTeX. In
#' html this isn't that tricky, you just use
#' the <br /> command but in LaTeX I often find
#' myself writing vbox/hbox stuff and therefore
#' I've created this simple helper function
#'
#' @param ... The lines that you want to be joined
#' @param html If HTML compatible output should be used. If \code{FALSE}
#'  it outputs LaTeX formatting. Note if you set this to 5
#'  then the html5 version of \emph{br} will be used: \code{<br>}
#'  otherwise it uses the \code{<br />} that is compatible
#'  with the xhtml-formatting.
#' @return string
#'
#' @examples
#' txtMergeLines("hello", "world")
#' txtMergeLines("hello", "world", html=FALSE)
#' txtMergeLines("hello", "world", list("A list", "is OK"))
#'
#' @family text formatters
#' @export
txtMergeLines <- function(..., html = 5){
  strings <- c()
  for (i in list(...)){
    if (is.list(i)){
      for(c in i)
        strings <- append(strings, i)
    }else{
      strings <- append(strings, i)
    }

  }
  if (length(strings) == 0){
    return("")
  }
  if (length(strings) == 1){
    strings <- gsub("\n", ifelse(html == 5, "<br>\n", "<br />\n"), strings)
    return(strings)
  }

  ret <- ifelse(html != FALSE, "", "\\vbox{")
  first <- TRUE
  for (line in strings){
    line <- as.character(line)
    if (first)
      ret <- paste0(ret, ifelse(html != FALSE, line, sprintf("\\hbox{\\strut %s}", line)))
    else
      ret <- paste0(ret, ifelse(html != FALSE,
                                paste(ifelse(html == 5, "<br>\n", "<br />\n"),
                                      line),
                                sprintf("\\hbox{\\strut %s}", line)))
    first <- FALSE
  }
  ret <- ifelse(html, ret, paste0(ret, "}"))

  return(ret)
}

#' SI or English formatting of an integer
#'
#' English uses ',' between every 3 numbers while the
#' SI format recommends a ' ' if x > 10^4. The scientific
#' form 10e+? is furthermore avoided.
#'
#' @param x The integer variable
#' @param language The ISO-639-1 two-letter code for the language of
#'  interest. Currently only english is distinguished from the ISO
#'  format using a ',' as the separator.
#' @param html If the format is used in html context
#'  then the space should be a non-breaking space, \code{&nbsp;}
#' @param ... Passed to \code{\link[base]{format}}
#' @return \code{string}
#'
#' @examples
#' txtInt(123)
#' txtInt(1234)
#' txtInt(12345)
#' txtInt(123456)
#'
#' @family text formatters#'
#' @export
txtInt <- function(x, language = "en", html = TRUE, ...){
  if (length(x) > 1){
    ret <- sapply(x, txtInt, language=language, html=TRUE, ...)
    if (is.matrix(x)){
      ret <- matrix(ret, nrow=nrow(x))
      rownames(ret) <- rownames(x)
      colnames(ret) <- colnames(x)
    }
    return(ret)
  }
  if (abs(x - round(x)) > .Machine$double.eps^0.5 &&
        !"nsmall" %in% names(list(...)))
    warning("The function can only be served integers, '", x, "' is not an integer.",
            " There will be issues with decimals being lost if you don't add the nsmall parameter.")

  if (language == "en")
    return(format(x, big.mark=",", scientific=FALSE, ...))

  if(x >= 10^4)
    return(format(x,
                  big.mark=ifelse(html, "&nbsp;", " "),
                  scientific=FALSE, ...))

  return(format(x, scientific=FALSE, ...))
}


#' Formats the p-values
#'
#' Gets formatted p-values. For instance
#' you often want 0.1234 to be 0.12 while also
#' having two values up until a limit,
#' i.e. 0.01234 should be 0.012 while
#' 0.001234 should be 0.001. Furthermore you
#' want to have < 0.001 as it becomes ridiculous
#' to report anything below that value.
#'
#' @param pvalues The p-values
#' @param lim.2dec The limit for showing two decimals. E.g.
#'  the p-value may be 0.056 and we may want to keep the two decimals in order
#'  to emphasize the proximity to the all-mighty 0.05 p-value and set this to
#'  \eqn{10^-2}. This allows that a value of 0.0056 is rounded to 0.006 and this
#'  makes intuitive sense as the 0.0056 level as this is well below
#'  the 0.05 value and thus not as interesting to know the exact proximity to
#'  0.05. \emph{Disclaimer:} The 0.05-limit is really silly and debated, unfortunately
#'  it remains a standard and this package tries to adapt to the current standards in order
#'  to limit publication associated issues.
#' @param lim.sig The significance limit for the less than sign, i.e. the '<'
#' @param html If the less than sign should be < or &lt;
#'  as needed for html output.
#' @param ... Currently only used for generating warnings of deprecated call
#'  parameters.
#' @return vector
#'
#' @examples
#' txtPval(c(0.10234,0.010234, 0.0010234, 0.000010234))
#' @family text formatters
#' @rdname txtPval
#' @export
txtPval <- function(pvalues,
                    lim.2dec = 10^-2,
                    lim.sig = 10^-4,
                    html=TRUE, ...){

  if (is.logical(html))
    html <- ifelse(html, "&lt; ", "< ")
  sapply(pvalues, function(x, lim.2dec, lim.sig, lt_sign){
    if (is.na(as.numeric(x))){
      warning("The value: '", x, "' is non-numeric and txtPval",
              " can't therfore handle it")
      return (x)
    }

    if (x < lim.sig)
      return(sprintf("%s%s", lt_sign, format(lim.sig, scientific=FALSE)))

    if (x > lim.2dec)
      return(format(x,
                    digits=2,
                    nsmall=-floor(log10(x))+1))

    return(format(x, digits=1, scientific=FALSE))
  }, lim.sig=lim.sig,
  lim.2dec = lim.2dec,
  lt_sign = html)
}

#' A convenient rounding function
#'
#' If you provide a string value in X the function will try to round this if
#' a numeric text is present. If you want to skip certain rows/columns then
#' use the excl.* arguments.
#'
#' @param x The value/vector/data.frame/matrix to be rounded
#' @param digits The number of digits to round each element to.
#'  If you provide a vector each element will apply to the corresponding columns.
#' @param excl.cols Columns to exclude from the rounding procedure.
#'  This can be either a number or regular expression. Skipped if x is a vector.
#' @param excl.rows Rows to exclude from the rounding procedure.
#'  This can be either a number or regular expression.
#' @param txt.NA The string to exchange NA with
#' @param dec The decimal marker. If the text is in non-english decimal
#'  and string formatted you need to change this to the apropriate decimal
#'  indicator.
#' @param ... Passed to next method
#' @return \code{matrix/data.frame}
#'
#' @examples
#' mx <- matrix(c(1, 1.11, 1.25,
#'                2.50, 2.55, 2.45,
#'                3.2313, 3, pi),
#'              ncol = 3, byrow=TRUE)
#' txtRound(mx, 1)
#' @export
#' @rdname txtRound
#' @family text formatters
txtRound <- function(x, ...){
  UseMethod("txtRound")
}

#' @export
#' @rdname txtRound
txtRound.default = function(x, digits = 0, txt.NA = "", dec = ".", ...){
  if(length(digits) != 1 & length(digits) != length(x))
    stop("You have ",
         length(digits),
         " digits specifications but a vector of length ",
         length(x),
         ": ",
         paste(x, collapse=", "))

  dec_str <- sprintf("^[^0-9\\%s-]*([\\-]{0,1}(([0-9]*|[0-9]+[ 0-9]+)[\\%s]|)[0-9]+)(|[^0-9]+.*)$",
                     dec, dec)
  if (is.na(x))
    return(txt.NA)
  if (!is.numeric(x) &&
      !grepl(dec_str, x))
    return(x)
  if (is.character(x) &&
      grepl(dec_str, x)){
    if (dec != ".")
      x <- gsub(dec, ".", x)

    # Select the first occurring number
    # remove any spaces indicating thousands
    # and convert to numeric
    x <-
      sub(dec_str, "\\1", format(as.numeric(x), scientific = FALSE, nsmall = 20)) %>%
      gsub(" ", "", .) %>%
      as.numeric
  }

  mapply(function(v, d){
    if (round(v, d) == 0)
      v <- 0
    sprintf(paste0("%.", d, "f"), v)
  }, x, digits)
}

#' @export
#' @rdname txtRound
txtRound.data.frame <- function(x, ...){
  i <- sapply(x, is.factor)
  if (any(i)){
    x[i] <- lapply(x[i], as.character)
  }

  x <- as.matrix(x)
  x <- txtRound.matrix(x, ...)

  return (as.data.frame(x, stringsAsFactors = FALSE))
}

#' @rdname txtRound
#' @export
txtRound.matrix <- function(x, digits = 0, excl.cols, excl.rows, ...){
  if(length(dim(x)) > 2)
    stop("The function only accepts vectors/matrices/data.frames as primary argument")

  rows <- 1L:nrow(x)
  if (!missing(excl.rows)){
    if (is.character(excl.rows)){
      excl.rows <- grep(excl.rows, rownames(x))
    }

    if (length(excl.rows) > 0)
      rows <- rows[-excl.rows]
  }

  cols <- 1L:ncol(x)
  if (!missing(excl.cols)){
    if (is.character(excl.cols)){
      excl.cols <- grep(excl.cols, colnames(x))
    }

    if (length(excl.cols) > 0)
      cols <- cols[-excl.cols]
  }

  if (length(cols) == 0)
    stop("No columns to round")

  if (length(rows) == 0)
    stop("No rows to round")

  if(length(digits) != 1 & length(digits) != length(cols))
    stop("You have ",
         length(digits),
         " digits specifications but ",
         length(cols),
         " columns to apply them to: ",
         paste(cols, collapse = ", "))

  ret_x <- x
  for (row in rows){
    ret_x[row, cols] <-
      mapply(txtRound, x[row, cols], digits,
             ...,
             USE.NAMES = FALSE)
  }

  return(ret_x)
}
