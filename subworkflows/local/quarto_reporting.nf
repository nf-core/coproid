//
// Subworkflow for quarto reporting
//

include { QUARTONOTEBOOK  } from '../../modules/nf-core/quartonotebook/main'

workflow QUARTO_REPORTING {

    take:
    ch_quarto

    main:

    ch_versions = Channel.empty()

    //
    // Quarto reports and extension files
    //
    coproid_notebook = file("${projectDir}/bin/coproid_test_report.qmd", checkIfExists: true) 
    extensions = Channel.fromPath("${projectDir}/assets/_extensions").collect()

    // Create a channel from the file
    Channel
        .of(coproid_notebook)
        .map { 
        coproid_notebook ->
            [   
                [
                'id': 'quarto_notebook'
                ],
            coproid_notebook
            ]
        }.dump(tag: 'quarto_notebook') 
        .set { ch_coproid_notebook }

    QUARTONOTEBOOK (
        ch_coproid_notebook,
        [],
        ch_quarto,
        extensions
    )

    emit:
    versions          = ch_versions

}
