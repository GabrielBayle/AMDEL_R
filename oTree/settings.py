 SESSION_CONFIGS = [
     dict(
         name="mecanisme_approbation_baseline",
         display_name="Mécanisme approbation - Baseline",
         treatment=0,   0=baseline, 1=majority, 2=unanimity
         num_demo_participants=6,
         app_sequence=["welcome",
                       "mecanisme_approbation",
                       "svo", "targetNLE", "crt7",
                       "nep_scale", "demographics2",
                       "mecanisme_approbation_final"],
         is_test=False,
         fill_auto=True
     ),
     dict(
         name="mecanisme_approbation_majority",
         display_name="Mécanisme approbation - Majority",
         treatment=1,   0=baseline, 1=majority, 2=unanimity
         num_demo_participants=6,
         app_sequence=[
             "welcome",
             "mecanisme_approbation",
             "svo", "targetNLE", "crt7",
             "nep_scale", "demographics2",
             "mecanisme_approbation_final"
         ],
         is_test=False,
         fill_auto=True
     ),
     dict(
         name="mecanisme_approbation_unanimity",
         display_name="Mécanisme approbation - Unanimity",
         treatment=2,   0=baseline, 1=majority, 2=unanimity
         num_demo_participants=6,
         app_sequence=["welcome",
                       "mecanisme_approbation",
                       "svo", "targetNLE", "crt7",
                       "nep_scale", "demographics2",
                       "mecanisme_approbation_final"],
         is_test=False,
         fill_auto=True
     ),
    ]
