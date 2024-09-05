from ._builtin import Page
from settings import LANGUAGE_CODE


class Welcome(Page):
    def vars_for_template(self):
        return dict(
            language=LANGUAGE_CODE
        )

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


page_sequence = [Welcome]
