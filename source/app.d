import std.stdio;
import std.file;
import std.path;
import std.algorithm: canFind;
import std.string;
import std.getopt;

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

    if(!localRepo.empty){
        writeln("Scanning ", localRepo, "...");

        int prefixLen = localRepo.length;
        int resolved = 0;

        foreach (string path; dirEntries(localRepo, SpanMode.depth)){
            if (isFile(path) && canFind([".pom", ".jar" ], extension(path))){
                auto artifactPath = path[prefixLen+1..$];

                Dependency dependency = parseDependency(artifactPath);

                writeln(artifactPath, " --> ", dependency);
                resolved++;
            }
        }

        writeln("=========================================");
        writeln("Resvoled: " , resolved, " artifacts.");

    } else {
        defaultGetoptPrinter("A tool for resolving differences between local and remote repos.",helpInfo.options);
    }
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

/*
    group:artfiact:version:type:classifier
    ROOT/GROUP/ARTIFACT/VERSION/ARTIFACT-VERSION-CLASSIFIER.TYPE
 */