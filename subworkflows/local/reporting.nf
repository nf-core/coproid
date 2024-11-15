//
// Subworkflow for quarto reporting
//

include { QUARTONOTEBOOK  } from '../../modules/nf-core/quartonotebook/main'

workflow QUARTONOTEBOOK {

    take:

    main:

    ch_versions = Channel.empty()

    //
    // Quarto reports and extension files
    //
    quality_controls_notebook = file("${projectDir}/bin/coproid.qmd", checkIfExists: true)


}
