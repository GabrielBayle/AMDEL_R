from otree.api import Submission

from . import pages
from ._builtin import Bot


class PlayerBot(Bot):

    def play_round(self):
        yield (
            pages.Final,
           {"comments": "This is an automatic comment. "
                        "This was a nice experiment ;-)"
            }
        )
        yield Submission(pages.Final_after_comments, check_html=False)
