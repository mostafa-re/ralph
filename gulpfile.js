const gulp = require("gulp"),
    watch = require("gulp-watch"),
    runSequence = require("run-sequence"),
    rename = require("gulp-rename"),
    bower = require("gulp-bower"),
    prefixer = require("gulp-autoprefixer"),
    sass = require("gulp-sass"),
    del = require("del"),
    vulcanize = require("gulp-vulcanize"),
    sequence = require("gulp-watch-sequence"),
    sourcemaps = require("gulp-sourcemaps");

const config = {
    nodeDir: "node_modules/",
    bowerDir: "bower_components/",
    elementsRoot: "src/ralph/admin/static/elements/",
    srcRoot: "src/ralph/static/src/",
    staticRoot: "src/ralph/static/",
    vendorRoot: "src/ralph/static/vendor/",
};

const sass_config = {
    outputStyle: "compressed",
    includePaths: [
        config.bowerDir + "foundation/scss",
        config.bowerDir + "fontawesome/scss",
        config.bowerDir + "chartist/dist/scss",
    ],
};

gulp.task("bower", function () {
    return bower().pipe(gulp.dest(config.bowerDir));
});

gulp.task("scss", function () {
    gulp.src(config.srcRoot + "scss/*.scss")
        .pipe(sourcemaps.init())
        .pipe(sass(sass_config).on("error", sass.logError))
        .pipe(prefixer())
        .pipe(sourcemaps.write("."))
        .pipe(gulp.dest(config.staticRoot + "css/"));
});

gulp.task("css", function () {
    const vendorFiles = [
        config.bowerDir + "normalize.css/normalize.css",
        config.bowerDir + "foundation-datepicker/css/foundation-datepicker.css",
        config.bowerDir + "angular-loading-bar/build/loading-bar.min.css",
    ];
    return gulp.src(vendorFiles).pipe(gulp.dest(config.vendorRoot + "css/"));
});

gulp.task("fonts", function () {
    const fontFiles = [
        config.bowerDir + "fontawesome/fonts/*.*",
        config.nodeDir + "vazirmatn/Round-Dots/misc/UI/fonts/ttf/*.*",
        config.nodeDir + "vazirmatn/Round-Dots/misc/UI/fonts/webfonts/*.*",
    ];
    return gulp.src(fontFiles).pipe(gulp.dest(config.vendorRoot + "fonts/"));
});

gulp.task("js", function () {
    const vendorFiles = [
        config.bowerDir + "fastclick/lib/fastclick.js",
        config.bowerDir + "jquery.cookie/jquery.cookie.js",
        config.bowerDir + "jquery/dist/jquery.js",
        config.bowerDir + "modernizr/modernizr.js",
        config.bowerDir + "foundation/js/foundation.min.js",
        config.bowerDir + "foundation-datepicker/js/foundation-datepicker.js",
        config.bowerDir + "angular-loading-bar/build/loading-bar.min.js",
        config.bowerDir + "webcomponentsjs/webcomponents-lite.js",
        config.bowerDir + "chartist/dist/chartist.js",
    ];
    gulp.src(vendorFiles).pipe(gulp.dest(config.vendorRoot + "js/"));
    gulp.src(config.bowerDir + "jquery-placeholder/jquery.placeholder.js")
        .pipe(rename("placeholder.js"))
        .pipe(gulp.dest(config.vendorRoot + "js"));

    const angularFiles = [
        config.bowerDir + "angular-breadcrumb/dist/angular-breadcrumb.min.js",
        config.bowerDir + "angular-cookies/angular-cookies.min.js",
        config.bowerDir + "angular/angular.min.js",
        config.bowerDir + "angular-resource/angular-resource.min.js",
        config.bowerDir + "angular-route/angular-route.min.js",
        config.bowerDir + "angular-ui-router/release/angular-ui-router.min.js",
    ];
    gulp.src(angularFiles).pipe(gulp.dest(config.vendorRoot + "js"));
});

gulp.task("clean:elements", function () {
    return del(["src/ralph/admin/static/bower_components/"]);
});

gulp.task("vulcanize", function () {
    return gulp
        .src(config.elementsRoot + "elements.html")
        .pipe(
            vulcanize({
                abspath: "",
                excludes: [],
                stripExcludes: false,
                stripComments: true,
                inlineCss: true,
                inlineScripts: true,
            })
        )
        .pipe(rename(config.elementsRoot + "elements-min.html"))
        .pipe(gulp.dest("."));
});

gulp.task("polymer-dev", function () {
    return gulp
        .src([config.bowerDir + "**/*"], { base: "." })
        .pipe(gulp.dest("src/ralph/admin/static/"));
});

gulp.task("watch", function () {
    // run "gulp dev" before
    gulp.watch(config.srcRoot + "scss/**/*.scss", ["scss"]);
    gulp.watch(
        [
            config.elementsRoot + "*.html",
            "!" + config.elementsRoot + "*-min.html",
        ],
        ["vulcanize"]
    );
});

gulp.task("dev", function (callback) {
    runSequence(
        "bower",
        "css",
        "fonts",
        "js",
        "scss",
        "polymer-dev",
        "vulcanize",
        callback
    );
});

gulp.task("build", function (callback) {
    runSequence("dev", "clean:elements", callback);
});

gulp.task("default", ["dev"]);
