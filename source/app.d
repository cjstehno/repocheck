import std.stdio;
import std.file;
import std.path;
import std.algorithm: canFind;
import std.string;
import std.getopt;
import std.datetime.stopwatch : StopWatch, AutoStart;

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

    if(!localRepo.empty){
        auto timer = StopWatch(AutoStart.yes);

        writeln("Scanning ", localRepo, "...");

        Dependency[] dependencies = scan(localRepo);
        writeln("Resvoled: " , dependencies.length, " artifacts.");

        writeln("Comparing local artifacts to ", remoteRepo, "...");
        verify(dependencies, remoteRepo);

        long ellapsed = timer.peek.total!"msecs";
        timer.stop();

        writeln("Done (", ellapsed, "ms).");

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
    // HEAD -> REPO/GROUP/ARTIFACT/VERSION/ARTIFACT-VERSION-CLASSIFIER.TYPE
    // report status
}

private Dependency parseDependency(string artifactPath){
    auto ext = extension(artifactPath);
    auto parts = split(artifactPath, "\\");

    string artifactGroup = join(parts[0..($-3)], "/");
    string artifactName = parts[$-3];

    string artifactVersion = parts[$-2];
    string artifactFile = parts[$-1];

    string classifier = null;
    if ( count(artifactFile, "-") > 2 ){
        auto start = artifactFile.lastIndexOf("-") + 1;
        auto end = artifactFile.lastIndexOf(".");
        classifier = artifactFile[start..end];

        artifactVersion = replace(artifactVersion, "-" ~ classifier, "");
    }

    return Dependency(artifactGroup, artifactName, artifactVersion, classifier, ext[1..$]);
}