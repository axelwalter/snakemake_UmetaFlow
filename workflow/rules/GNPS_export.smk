import glob
from os.path import join 

# 1) Filter out the features that do not have an MS2 pattern (no protein ID annotations)

if config["rules"]["requantification"]:
    rule FileFilter:
        input:
            join("results", "Interim", "Requantification", "consenus_features.consensusXML")
        output:
            join("results", "Interim", "GNPS", "filtered.consensusXML")
        log: join("workflow", "report", "logs", "GNPS", "FileFilter.log")
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            FileFilter -id:remove_unannotated_features -in {input} -out {output} -no_progress -log {log} 2>> {log} 
            """
else:
    rule FileFilter:
        input:
            join("results", "Interim", "Preprocessing", "consenus_features.consensusXML")
        output:
            join("results", "Interim", "GNPS", "filtered.consensusXML")
        log: join("workflow", "report", "logs", "GNPS", "FileFilter.log")
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            FileFilter -id:remove_unannotated_features -in {input} -out {output} -no_progress -log {log} 2>> {log} 
            """

# 2) GNPS_export creates an mgf file with only the MS2 information of all files (introduce mzml files with spaces between them)

rule GNPS_export:
    input:
        var1= join("results", "Interim", "GNPS", "filtered.consensusXML"),
        var2= expand(join("results", "Interim", "mzML", "Aligned_{samples}.mzML"), samples=SUBSAMPLES)
    output:
        out1= join("results", "GNPS", "MSMS.mgf"),
        out2= join("results", "GNPS", "FeatureQuantificationTable.txt"), 
        out3= join("results", "GNPS", "SuppPairs.csv"),
        out4= join("results", "GNPS", "metadata.tsv")
    log: join("workflow", "report", "logs", "GNPS", "GNPS_export.log")
    conda:
        join("..", "envs", "openms.yaml")
    threads: config["system"]["threads"]
    shell:
        """
        GNPSExport -in_cm {input.var1} -in_mzml {input.var2} -out {output.out1} -out_quantification {output.out2} -out_pairs {output.out3} -out_meta_values {output.out4} -threads {threads} -no_progress -log {log} 2>> {log} 
        """