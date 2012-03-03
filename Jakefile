/*
 * Jakefile
 * ChargrinRM
 *
 * Created by You on January 22, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    OS = require("os");

app ("ChargrinRM", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "ChargrinRM.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("ChargrinRM");
    task.setIdentifier("com.yourcompany.ChargrinRM");
    task.setVersion("1.0");
    task.setAuthor("Your Company");
    task.setEmail("feedback @nospam@ yourcompany.com");
    task.setSummary("ChargrinRM");
    task.setSources((new FileList("**/*.j")).exclude(FILE.join("Build", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");
    task.setNib2CibFlags("-R Resources/");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("default", ["ChargrinRM"], function()
{
    printResults(configuration);
});

task ("build", ["default"]);

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("run", ["debug"], function()
{
    OS.system(["open", FILE.join("Build", "Debug", "ChargrinRM", "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", FILE.join("Build", "Release", "ChargrinRM", "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", "ChargrinRM"));
    OS.system(["press", "-f", FILE.join("Build", "Release", "ChargrinRM"), "/Volumes/Emma/Users/boog/Sites/cableresearcher/static"]);
    printResults("Deployment")
});

task ("desktop", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Desktop", "ChargrinRM"));
    require("cappuccino/nativehost").buildNativeHost(FILE.join("Build", "Release", "ChargrinRM"), FILE.join("Build", "Desktop", "ChargrinRM", "ChargrinRM.app"));
    printResults("Desktop")
});

task ("run-desktop", ["desktop"], function()
{
    OS.system([FILE.join("Build", "Desktop", "ChargrinRM", "ChargrinRM.app", "Contents", "MacOS", "NativeHost"), "-i"]);
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, "ChargrinRM"));
    print("----------------------------");
}
