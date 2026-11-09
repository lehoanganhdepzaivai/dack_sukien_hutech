# PDF.js runtime

Version 6.2.108, matching `printing` 5.15.1's default runtime. These files are
served locally so viewing a student's generated activity report does not require
a PDF rendering CDN. The PDF data is processed in the browser.

Upstream: https://github.com/mozilla/pdf.js

Distribution sources:
- https://unpkg.com/pdfjs-dist@6.2.108/build/pdf.min.mjs
- https://unpkg.com/pdfjs-dist@6.2.108/build/pdf.worker.min.mjs
- https://unpkg.com/pdfjs-dist@6.2.108/LICENSE

Apache-2.0 license is included in `LICENSE`. This viewer is used for generated
reports with embedded fonts; it is not a general-purpose PDF upload viewer.
