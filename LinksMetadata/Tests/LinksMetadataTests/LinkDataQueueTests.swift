//
//  File.swift
//  
//
//  Created by Matt on 10/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import XCTest
import Links
@testable import LinksMetadata

final class LinkDataQueueTests: XCTestCase {
    func testSerialAsyncLinkDownload() async {
        let linkUrls = [
            "https://docs.kanaries.net/rath/tutorials/data-painter/",
            "https://zeus.ugent.be/blog/22-23/repurposing_ewaste/",
            "https://www.publicbooks.org/data-free-disney/",
            "https://www.npr.org/2023/02/14/1156567743/health-east-palestine-ohio-train-derailment-chemicals",
            "https://arstechnica.com/gadgets/2023/02/google-employees-criticize-ceo-for-dumpster-fire-response-to-chatgpt/",
            "https://om.co/2023/02/08/does-google-need-a-new-ceo/",
            "https://arstechnica.com/science/2023/02/its-not-aliens-itll-probably-never-be-aliens-so-stop-please-just-stop/",
            "https://arstechnica.com/science/2023/02/taking-a-walk-on-the-random-side-helps-mexican-jumping-beans-find-shade/",
            "https://www.smithsonianmag.com/innovation/how-does-human-echolocation-work-180965063/",
            "https://arstechnica.com/cars/2023/02/the-us-air-force-successfully-tested-this-ai-controlled-jet-fighter/",
            "https://serokell.io/blog/rust-vs-haskell",
            "http://www.ibmsystem3.nl/my5410/my5410.html",
            "https://jeremykun.com/2023/02/13/googles-fully-homomorphic-encryption-compiler-a-primer/",
            "https://www.theguardian.com/technology/2023/feb/14/fca-and-west-yorkshire-police-raid-crypto-operators-in-uk-first",
            "https://blog.glyph.im/2023/02/data-classification.html",
            "https://www.theguardian.com/world/2023/feb/14/bbc-offices-india-raided-tax-officials-modi-documentary-fallout",
            "https://blog.trailofbits.com/2023/02/14/curl-audit-fuzzing-libcurl-command-line-interface/",
            "https://boards.greenhouse.io/supabase/jobs/4796595004",
            "https://www.technologyreview.com/2023/02/14/1067869/rust-worlds-fastest-growing-programming-language/",
            "https://www.wired.com/story/eric-schmidt-is-building-the-perfect-ai-war-fighting-machine/",
            "https://www.economist.com/business/2023/02/09/the-pitfalls-of-loving-your-job-a-little-too-much",
            "https://www.thomann.ae/korg_nu_tekt_nts_2_oscilloscope_kit.htm",
            "http://rachelbythebay.com/w/2023/02/13/broken/",
            "http://avherald.com/h?article=50526a09",
            "https://yosefk.com/blog/people-can-read-their-managers-mind.html",
            "http://ghostinfluence.com/the-ultimate-retaliation-pranking-my-roommate-with-targeted-facebook-ads/",
            "https://www.ft.com/content/fb1254dd-a011-44cc-bde9-a434e5a09fb4",
            "https://outerproduct.net/boring/2023-02-11_term-loop.html",
            "https://www.grc.com/otg/uheprng.htm",
            "https://lockval.com",
            "https://utcc.utoronto.ca/~cks/space/blog/linux/LinuxIpFwmarkMasks",
            "https://www.tbray.org/ongoing/When/202x/2023/02/09/Monospace",
            "https://steveblank.com/2023/02/14/startups-that-have-employees-in-offices-grow-3-%c2%bd-times-faster/",
            "https://webkit.org/blog/13851/declarative-shadow-dom/",
            "https://gregorygundersen.com/blog/2023/02/11/dimensional-analysis/",
            "https://academic.oup.com/bioscience/article/49/6/453/229475",
            "https://boilingsteam.com/framework-laptop-review-intel-12th-gen-laptop-with-linux-the-definitive-review/",
            "https://www.economist.com/finance-and-economics/2023/02/13/war-and-subsidies-have-turbocharged-the-green-transition",
            "https://elektrotanya.com/",
            "https://www.ft.com/content/6e912f25-f1b7-4b19-b370-007fbc867246",
            "https://www.youtube.com/watch?v=exSRG-iL74Q",
            "https://pix2pixzero.github.io/",
            "https://support.mozilla.org/en-US/kb/containers",
            "https://twitter.com/BigscreenVR/status/1625152589624135698",
            "https://www.the-odin.com/",
            "https://www.theregister.com/2023/02/13/linux_ai_assistant_killed_off/",
            "https://github.com/hyperfiddle/electric",
            "https://www.joelonsoftware.com/2001/10/14/in-defense-of-not-invented-here-syndrome/",
            "https://www.ft.com/content/fb1254dd-a011-44cc-bde9-a434e5a09fb4",
            "https://github.com/zloirock/core-js/blob/master/docs/2023-02-14-so-whats-next.md",
            "https://gist.github.com/gtallen1187/e83ed02eac6cc8d7e185",
            "https://blog.frankel.ch/null-safety-java-vs-kotlin/",
            "https://github.com/schibsted/WAAS",
            "https://edw.is/using-lua-with-cpp/",
            "https://fosdem.org/2023/schedule/event/rust_coreutils/",
            "https://lareviewofbooks.org/article/a-lost-world-on-travis-zadehs-wonders-and-rarities/",
            "https://stephan.lachnit.xyz/posts/2023-02-08-debian-sbuild-mmdebstrap-apt-cacher-ng/",
            "https://dkb.blog/p/bing-ai-cant-be-trusted",
            "https://ansuz.sooke.bc.ca/entry/23",
            "https://paavandesign.com/blog/ostaulta/",
            "https://blog.cloudflare.com/cloudflare-mitigates-record-breaking-71-million-request-per-second-ddos-attack/",
            "https://twitter.com/esaoperations/status/1624901825785724929",
            "https://torrentfreak.com/z-library-returns-on-the-clearnet-in-full-hydra-mode-230213/",
            "https://www.businessinsider.com/salesforce-ceo-benioff-10-day-digital-detox-after-layoffs-report-2023-2",
            "https://www.ted.com/talks/donald_hoffman_do_we_see_reality_as_it_is",
            "https://fosdem.org/2023/schedule/event/matrix20/",
            "https://www.pixelated-noise.com/blog/2023/02/09/flatten-routes/index.html",
            "https://www.scientificamerican.com/article/let-teenagers-sleep/",
            "https://github.com/4silvertooth/QwikTape",
            "https://stackoverflow.com/questions/2669690/why-does-google-prepend-while1-to-their-json-responses",
            "https://twitter.com/karrisaarinen/status/1623857893090152448",
            "https://www.swpc.noaa.gov/news/return-x-flares",
            "https://github.com/hunkimForks/chatgpt-arxiv-extension",
            "https://www.fastcompany.com/90848025/ohio-train-derailment-toxic-chemicals-pvc-spill-fire-disaster",
            "https://www.designhat.ai/",
            "https://www.nytimes.com/2023/02/13/health/teen-girls-sadness-suicide-violence.html",
            "https://paperlist.io/",
            "https://publicdomainreview.org/collection/concealing-coloration",
            "https://www.jabperf.com/my-fear-of-commitment-to-the-1st-cpu-core/",
            "https://fineflows.com",
            "https://toodle.studio",
            "https://dilbert.com/strip/2023-02-11",
            "https://80.lv/articles/geopipe-offers-3d-model-of-new-york-for-free/",
            "https://www.the-tls.co.uk/articles/the-american-sonnett-dora-malech-laura-t-smith-book-review-anahid-nersessian/",
            "https://www.charliechaplin.com/",
            "https://wiki.debian.org/PrivacyIssues",
            "https://www.hybridlogic.co.uk/2023/02/clog/",
            "https://fasterthanli.me/articles/the-bottom-emoji-breaks-rust-analyzer",
            "https://seb.deleuze.fr/the-huge-potential-of-kotlin-wasm/",
            "https://github.com/ebitengine/purego",
            "https://cacm.acm.org/blogs/blog-cacm/269854-inside-the-heart-of-chatgpts-darkness/fulltext",
            "https://github.com/tancik/Illusion-Diffusion",
            "https://www.washingtonpost.com/technology/2023/02/13/mental-health-data-brokers/"
        ]

        let queue = LinkDataQueue(headerFields: ["User-Agent": "Ulry"])
        let links = linkUrls.map { Link(url: $0) }
        let _ = try! await queue.process(links)
    }
}
