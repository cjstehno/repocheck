import std.stdio;
import std.file;
import std.path;
import std.algorithm: canFind;
import std.string;
import std.getopt;
import std.datetime.stopwatch : StopWatch, AutoStart;
import std.net.curl;
import std.parallelism;
import core.atomic;
import std.algorithm.sorting;

struct Dependency {
    string group;
    string artifact;
    string vers;
    string classifier;
    string type;
}

void main(string[] args) {
    string localRepo = "";
    string remoteRepo = "";

    auto helpInfo = getopt(
        args,
        "local", "Path to the local repo.", &localRepo,
        "remote", "URL for the remote repo.", &remoteRepo
    );

    // FIXME: look into pointers/reference usage
    // FIXME: use string formatters
    // FIXME: sort the output
    // FIXME: convert the struct to a class with methods

    if(!localRepo.empty){
        auto timer = StopWatch(AutoStart.yes);

        writeln("Scanning ", localRepo, "...");

        Dependency[] dependencies = scan(localRepo);
        writeln("Resvoled: " , dependencies.length, " artifacts.");

        writeln("Comparing local artifacts to ", remoteRepo, "...");
        verify(dependencies, remoteRepo);

        long ellapsed = timer.peek.total!"msecs" / 1000;
        timer.stop();

        writeln("Done (", ellapsed, " seconds).");

    } else {
        defaultGetoptPrinter("A tool for resolving differences between local and remote repos.",helpInfo.options);
    }
}

private Dependency[] scan(string localRepo){
    int prefixLen = localRepo.length;

    Dependency[] dependencies = [];

    foreach (string path; dirEntries(localRepo, SpanMode.depth)){
        if (isFile(path) && canFind([".pom", ".jar" ], extension(path))){
            dependencies ~= parseDependency(path[prefixLen+1..$]);
        }
    }

    return dependencies;
}

private void verify(Dependency[] dependencies, string remoteRepo){
    string[] missings = [];

    foreach(Dependency dep; parallel(dependencies)){
        if( !existsInRepo(dep, remoteRepo) ){
            missings ~= (replace(dep.group, "/", ".") ~ ":" ~ dep.artifact ~ ":" ~ dep.vers ~ ":" ~ dep.classifier ~ ":" ~ dep.type);
        }
    }

    writeln("Found ", missings.length, " artifacts in the local repo that are not in the remote repo.");

    missings.sort();

    foreach(string dep; missings){
        writeln("Missing: ", dep);
    }
}

private bool existsInRepo(Dependency dependency, string repo){
    string artifactFile = dependency.artifact ~ "-" ~ dependency.vers;
    if( dependency.classifier != null && !dependency.classifier.empty){
        artifactFile = artifactFile ~ "-" ~ dependency.classifier;
    }
    artifactFile = artifactFile ~ "." ~ dependency.type;

    auto http = HTTP();
    http.handle.set(CurlOption.ssl_verifypeer, 0);
    http.method = HTTP.Method.head;
    http.url = repo ~ "/" ~ dependency.group ~ "/" ~ dependency.artifact ~ "/" ~ dependency.vers ~ "/" ~ artifactFile;
    http.perform();

    return http.statusLine().code == 200;
}

private Dependency parseDependency(string artifactPath){
    // path: GROUP(a/b/c)/NAME/VERSION/NAME-VERSION-CLASSIFIER.TYPE
    auto parts = split(artifactPath, "\\"); // TODO: can I make this the platform separator?

    string depGroup = join(parts[0..($-3)], "/");   // GROUP(a/b/c)
    string depName = parts[$-3].dup;                // NAME
    string depVers = parts[$-2].dup;                // VERSION
    string depFile = parts[$-1].dup;                // NAME-VERSION-CLASSIFIER.TYPE
    string depType = extension(artifactPath)[1..$]; // TYPE

    string depClassifier = replace(replace(depFile, depName ~ "-" ~ depVers, ""), "." ~ depType, "");
    if( depClassifier.startsWith("-") ){
        depClassifier = depClassifier[1..$];
    }

    return Dependency(depGroup, depName, depVers, depClassifier, depType);
}

// FIXME: break this into another file?
unittest {
    assert( parseDependency("org\\foo\\bar\\baz\\1.2.3\\baz-1.2.3.jar") == Dependency( "org/foo/bar", "baz", "1.2.3", null, "jar" ) , "Dependency without classifier.");
    assert( parseDependency("org\\foo\\bar\\baz\\1.2.3\\baz-1.2.3-bing.jar") == Dependency( "org/foo/bar", "baz", "1.2.3", "bing", "jar" ) , "Dependency with classifier.");
}