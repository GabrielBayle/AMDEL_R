import random
from datetime import date

from django_countries import countries

from . import pages
from ._builtin import Bot
from .models import Constants


class PlayerBot(Bot):
    def play_round(self):
        today = date.today().year
        yield (pages.DemogQuestionnaire,
               dict(
                   year_of_birth=random.randint(today - 100, today - 15),
                   gender=random.randint(0, 1),
                   nationality=random.choice(list(countries.alt_codes.keys())),
                   marital_status=random.randint(0, 4),
                   student=random.choice([True, False]),
                   study_level=random.randint(0, 7),
                   study_discipline=random.randint(0, len(Constants.disciplines) - 2),
                   socioprofessional_group=random.randint(1, 8),
                   experiment_participation=random.choice([True, False])
               ))
