## copy latest allrefs.bib file
#if (!nzchar(Sys.getenv("QUARTO_PROJECT_RENDER_ALL"))) {
#  quit()
#}

#file.copy(from="../../survbib/allrefs.bib",
#          to="scripts/allrefs.bib",
#          overwrite=TRUE)

rmarkdown::render("scripts/allrefs.Rmd")


## remove first 5 line from references
inputtext <- readLines("scripts/allrefs.md")
file.remove("scripts/allrefs.md")
newlinenum <- 1 
outputtext <- ""
for (i in 6:length(inputtext)) { 
  currentline <- inputtext[i]
  if(currentline != "") {
    outputtext[newlinenum] <- paste(outputtext[newlinenum], currentline,sep= " ")
  } 
  else {
    newlinenum <- newlinenum + 1
    outputtext[newlinenum] <- ""
    outputtext[newlinenum] <- currentline
    newlinenum <- newlinenum + 1     
    outputtext[newlinenum] <- ""
  }
}

##  Convert Lambert PC to **Lambert PC**
outputtext <- gsub( "Lambert PC", "<b>Lambert PC</b>", outputtext)
## finally change all cases of "</span><span class="csl-right-inline">" to ""
outputtext <- gsub( "</span><span class=\"csl-right-inline\">", "", outputtext)


cat(outputtext, file="scripts/allrefs.html", sep="\n")



