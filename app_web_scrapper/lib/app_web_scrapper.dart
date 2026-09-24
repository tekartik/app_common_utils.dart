/// Static web site scrapper: fetch start urls, follow their links (html,
/// css, javascript imports, optionally javascript/json strings) and save
/// every file to a fs_shim directory as `<host>/<path>`.
library;

export 'src/link.dart'
    show
        WebScrapperLink,
        WebScrapperLinkKind,
        WebScrapperContentFormat,
        webScrapperContentFormat;
export 'src/link_extractor.dart' show WebScrapperLinkExtractor;
export 'src/local_path.dart'
    show webScrapperDefaultLocalPath, webScrapperHtmlLocalPath;
export 'src/web_scrapper.dart'
    show
        WebScrapper,
        WebScrapperContent,
        WebScrapperEntry,
        WebScrapperEntryStatus,
        WebScrapperResult;
export 'src/web_scrapper_options.dart'
    show WebScrapperOptions, WebScrapperContentHandler, WebScrapperEntryHandler;
