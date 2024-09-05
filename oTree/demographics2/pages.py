import random
from datetime import date

from ._builtin import Page
from .models import countries


class DemogQuestionnaire(Page):
    form_model = "player"
    form_fields = ["year_of_birth", "gender", "nationality", "marital_status", "socioprofessional_group",
                   "study_level", "study_discipline", "experiment_participation"]

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        self.player.student = (self.player.socioprofessional_group == 9)
        if self.timeout_happened:
            self.player.year_of_birth = random.choice(range(date.today().year - 15, date.today().year - 101, -1))
            self.player.gender = random.choice([0, 1])
            self.player.nationality = random.choice([c[0] for c in countries])
            self.player.marital_status = random.choice(range(5))
            self.player.socioprofessional_group = random.choice(range(1, 10))
            self.player.student = (self.player.socioprofessional_group == 9)
            self.player.study_level = random.choice(range(8))
            self.player.study_discipline = random.choice(range(27))


page_sequence = [DemogQuestionnaire]
