var GetURL = function() {};
 
GetURL.prototype = {
    run: function(arguments) {
        let url = document.URL
        let title
        
        try {
            title = document.getElementsByTagName("title")[0].text;
        } catch (err) {
            title = ""
        }
        
        try {
            var meta = document.getElementsByTagName("meta");
            var dict = {};
            
            for (var i = 0; i < meta.length; i++) {
                let key = meta[i].name;
                let content = meta[i].content;

                if (key !== "" && content !== "") {
                  dict[key] = content;
                }
            }
        } catch (err) {
            dict = { "empty": true }
        }
        
        arguments.completionFunction({
            "url" : document.URL,
            "title": title,
            "dictData": dict
        });
    }
};
 
var ExtensionPreprocessingJS = new GetURL;
