# downloadmanga
This folder has several different implementation of webscraping mangastream
and downloading the image consequently.  
The different implementation greatly differ on how we get the content, parse
the xml/html page, extract the information and lastly download the file.  

The implementation is listed below with sorted to created time ascendingly:

1. `downloadmanga.nim`
2. `downloadmanga_async.nim`
3. `downloadmanga_xmlparse.nim`
4. `downloadmanga_poolconnection.nim`

The process flow can be viewed as

```
get page -> extract info -> download file
```

## downloadmanga.nim
This file has several different ways on extracting the info from html page.  
The fetching is done synchronously so the process i.e. like above mentioned.


Several ways of extracting in this file are

1. `Parse html -> XmlNode -> findAll "div"`
2. `Define peg -> find matches`
3. `string find`

Each implementation greatly differ in usage with method (1) is easiest yet
the most inefficient due to unnecessary parsing all nodes.  
The peg extracting is in middle because we need to find the correct grammar
to match.  
The lastly, `string find` is the most basic, hardest of all above and most efficient because we only find the information we need.  
In term of efficiency maybe method (2) and method (3) about the same.

## downloadmanga_async.nim
This using `html parsing` for extracting the information from page but the
different with previous implementation, this is done asynchronously.  
The getting page is still synchronously, because of there's no way to know
next page without getting extracted information, but for downloading it's
done asynchronously.

## downloadmanga_xmlparse.nim
This has different way to extract xml/html string. This is efficiently
done with xml parsing event and only getting the information we need.  
Improvment from previous `downloadmanga_async.nim`.

## downloadmanga_poolconnection.nim
This is more elaborate on how we download the file. In previous implementations,
all connection is spawned everytime we need to download a file. Hence the
inefficiency because we allocate connection and deallocate immediately.  
This implementation done by defining pool of `AsyncHttpClient` and juggling
the download operations with defined pool of client.
