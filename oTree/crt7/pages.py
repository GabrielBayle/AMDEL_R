from ._builtin import Page
from .models import Constants


class Cognitive(Page):
    timeout_seconds = Constants.temps_max * 60
    form_model = "player"
    form_fields = ["crt_{}".format(i) for i in range(1, len(Constants.answers) + 1)]

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        self.player.compute_score()


class Summary(Page):
    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


page_sequence = [Cognitive, Summary]
