import glob
from os.path import join 

# Annotate with metabolite annotations level 2 (MSI level 2) using the OpenMS algorithm MetaboliteSpectralMatcher with an MGF -or MSP- format file library (you can download publicly available ones and/or use in-house libraries):

rule converter:
    input:
        join("results", "GNPSexport", "MSMS.mgf")
    output:
        join("results", "Interim", "annotations", "MSMS.mzML")
    log: join("workflow", "report", "logs", "annotate", "converter.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        FileConverter -in {input} -out {output}  -no_progress -log {log} 2>> {log}
        """

MGF_library = find_files("resources", "*.mgf")
if MGF_library:
    print("computing MSMS matches with library:", MGF_library)
    rule spectral_matcher:
        input:
            mzml= join("results", "Interim", "annotations", "MSMS.mzML"),
            database= glob.glob(join("resources", "*.mgf"))
        output:
            join("results", "Interim", "annotations", "MSMSMatcher.mzTab")
        log: join("workflow", "report", "logs", "annotate", "spectral_matcher.log")
        threads: config["system"]["threads"]
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            MetaboliteSpectralMatcher -algorithm:merge_spectra "false" -in {input.mzml} -database {input.database} -out {output} -threads {threads} -no_progress -log {log} 2>> {log}
            """  

    if config["rules"]["sirius_csi"]:
        rule MSMS_annotations:
            input:
                MZTAB = join("results", "Interim", "annotations", "MSMSMatcher.mzTab"),
                MGF = join("results", "GNPSexport", "MSMS.mgf"),
                MZML = join("results", "Interim", "annotations", "MSMS.mzML"),
                MATRIX= join("results", "annotations", "FeatureTable_siriuscsi.tsv")
            output:
                MSMS_MATRIX= join("results", "annotations", "FeatureTable_MSMS.tsv")
            log: join("workflow", "report", "logs", "annotate", "MSMS_annotations.log")
            threads: config["system"]["threads"]
            conda:
                join("..", "envs", "pyopenms.yaml")
            shell:
                """
                python workflow/scripts/MSMS_annotations.py {input.MZTAB} {input.MGF} {input.MZML} {input.MATRIX} {output.MSMS_MATRIX} > /dev/null 2>> {log}
                """

    elif config["rules"]["sirius"]:
            rule MSMS_annotations:
                input:
                    MSMS = join("results", "Interim", "annotations", "MSMSMatcher.mzTab"),
                    MGF = join("results", "GNPSexport", "MSMS.mgf"),
                    MZML = join("results", "Interim", "annotations", "MSMS.mzML"),
                    MATRIX= join("results", "annotations", "FeatureTable_sirius.tsv")
                output:
                    MSMS_MATRIX= join("results", "annotations", "FeatureTable_MSMS.tsv")
                log: join("workflow", "report", "logs", "annotate", "MSMS_annotations.log")
                threads: config["system"]["threads"]
                conda:
                    join("..", "envs", "pyopenms.yaml")
                shell:
                    """
                    python workflow/scripts/MSMS_annotations.py {input.MSMS} {input.MGF} {input.MZML} {input.MATRIX} {output.MSMS_MATRIX} > /dev/null 2>> {log}
                    """

    else:
        rule MSMS_annotations:
            input:
                MSMS = join("results", "Interim", "annotations", "MSMSMatcher.mzTab"),
                MGF = join("results", "GNPSexport", "MSMS.mgf"),
                MZML = join("results", "Interim", "annotations", "MSMS.mzML"),
                MATRIX= join("results", "Preprocessed", "FeatureMatrix.tsv")
            output:
                MSMS_MATRIX= join("results", "annotations", "FeatureTable_MSMS.tsv")
            log: join("workflow", "report", "logs", "annotate", "MSMS_annotations.log")
            threads: config["system"]["threads"]
            conda:
                join("..", "envs", "pyopenms.yaml")
            shell:
                """
                python workflow/scripts/MSMS_annotations.py {input.MSMS} {input.MGF} {input.MZML} {input.MATRIX} {output.MSMS_MATRIX} > /dev/null 2>> {log}
                """

else:
    print("No MS2 reference library file found!")
    rule MSMS_annotations:
            input:
                MATRIX= join("results", "Preprocessed", "FeatureMatrix.tsv")
            output:
                MSMS_MATRIX= join("results", "annotations", "FeatureTable_MSMS.tsv"),
                MZTAB = join("results", "Interim", "annotations", "MSMSMatcher.mzTab")
            log: join("workflow", "report", "logs", "annotate", "MSMS_annotations.log")
            threads: config["system"]["threads"]
            conda:
                join("..", "envs", "pyopenms.yaml")
            shell:
                """
                cp {input.MATRIX} {output.MSMS_MATRIX} && echo "No MGF library file was found" > {output.MZTAB} > /dev/null 2>> {log}
                """