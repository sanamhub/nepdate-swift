using System.Runtime.CompilerServices;
using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Environments;
using BenchmarkDotNet.Jobs;
using BenchmarkDotNet.Running;
using DotnetBench;
using NepDate;

Console.OutputEncoding = System.Text.Encoding.UTF8;

if (args.Length > 0 && args[0] == "--inputs")
{
    // Prints the 64 inputs and the struct size, for docs/benchmarks/dotnet.md and the ports.
    Console.WriteLine($"sizeof(NepaliDate) = {Unsafe.SizeOf<NepaliDate>()} bytes");
    for (var i = 0; i < Inputs.Count; i++)
    {
        var (y, m, d) = Inputs.Ad[i];
        var p = Inputs.PatroBs[i];
        Console.WriteLine($"{i}\t{Inputs.Serials[i]}\t{Inputs.Text[i]}\t{y:D4}-{m:D2}-{d:D2}\t{Inputs.PatroSerials[i]}\t{p.Y:D4}-{p.M:D2}-{p.D:D2}");
    }
    return;
}

// spec/BENCHMARK.md §1 pins the reference machine to logical CPU 2 (mask 0x4). A shared runner has
// no such core and macOS has no process affinity, so the pin is applied on Linux only.
var job = Job.Default.WithRuntime(CoreRuntime.Core10_0);
if (OperatingSystem.IsLinux())
{
    job = job.WithAffinity((IntPtr)0x4);
}
var config = DefaultConfig.Instance.AddJob(job);

BenchmarkSwitcher.FromAssembly(typeof(Benchmarks).Assembly).Run(args, config);
