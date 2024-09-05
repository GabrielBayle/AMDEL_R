from django.utils.translation import gettext as _

from ._builtin import Page, WaitPage
from .models import Constants


class Presentation(Page):
    def is_displayed(self):
        return self.round_number == 1

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class Instructions(Page):
    def is_displayed(self):
        return self.round_number == 1 or self.round_number == Constants.round_second_part

    def vars_for_template(self):
        return self.player.vars_for_template()

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        self.subsession.set_understanding()


class InstructionsWaitMonitor(Page):
    def is_displayed(self):
        return (self.round_number == 1 or self.round_number == Constants.round_second_part) and \
               not self.subsession.is_test

    def vars_for_template(self):
        return self.player.vars_for_template()

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class Understanding(Page):
    form_model = "player"

    def get_form_fields(self):
        return [f"understanding_{i}" for i in range(len(self.session.vars["understanding"]))]

    def is_displayed(self):
        return self.round_number == 1 or (
                    self.round_number == Constants.round_second_part and self.subsession.treatment != Constants.baseline)

    def vars_for_template(self):
        return self.player.vars_for_template()

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        self.player.compute_understanding_faults()


class UnderstandingResults(Page):
    def is_displayed(self):
        return self.round_number == 1 or (
                    self.round_number == Constants.round_second_part and self.subsession.treatment != Constants.baseline)

    def vars_for_template(self):
        existing = self.player.vars_for_template()
        understanding = self.session.vars["understanding"]
        for i, q in enumerate(understanding):
            q["player_rep"] = getattr(self.player, f"understanding_{i}")
        existing.update(dict(understanding=understanding))
        return existing

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class UnderstandingResultsWaitForAll(WaitPage):
    body_text = _("En attente des autres participants")
    wait_for_all_groups = True

    def is_displayed(self):
        return self.round_number == 1 or (
                    self.round_number == Constants.round_second_part and self.subsession.treatment != Constants.baseline)


class Extraction(Page):
    form_model = "player"
    form_fields = ["extraction"]

    def vars_for_template(self):
        return self.player.vars_for_template()

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class ExtractionWaitForAll(WaitPage):
    body_text = _("En attente des autres participants")
    wait_for_all_groups = True
    after_all_players_arrive = "set_groups_extractions"


class Approbation(Page):
    form_model = "player"
    form_fields = ["approbation"]

    def is_displayed(self):
        return self.round_number >= Constants.round_second_part and \
               (self.subsession.treatment == Constants.unanimity or self.subsession.treatment == Constants.majority)

    def vars_for_template(self):
        existing = self.player.vars_for_template()
        existing.update(dict(
            other_1=self.player.get_others_in_group()[0].extraction,
            other_2=self.player.get_others_in_group()[1].extraction,
            other_1_payoff=int(self.player.get_others_in_group()[0].payoff),
            other_2_payoff=int(self.player.get_others_in_group()[1].payoff)
        ))
        return existing

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class ApprobationWaitForAll(WaitPage):
    body_text = _("En attente des autres participants")
    wait_for_all_groups = True
    after_all_players_arrive = "set_groups_approbation"

    def is_displayed(self):
        return self.round_number >= Constants.round_second_part and \
               (self.subsession.treatment == Constants.unanimity or self.subsession.treatment == Constants.majority)


class ApprobationResults(Page):
    def is_displayed(self):
        return self.round_number >= Constants.round_second_part and \
               (self.subsession.treatment == Constants.unanimity or self.subsession.treatment == Constants.majority)

    def vars_for_template(self):
        return self.player.vars_for_template()

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


class ApprobationResultsWaitForAll(WaitPage):
    body_text = _("En attente des autres participants")
    wait_for_all_groups = True

    def is_displayed(self):
        return self.round_number >= Constants.round_second_part and \
               (self.subsession.treatment == Constants.unanimity or self.subsession.treatment == Constants.majority)


class ExtractionDictator(Page):
    form_model = "group"
    form_fields = ["extraction_dictator"]

    def is_displayed(self):
        if self.player.round_number < Constants.round_second_part:
            return False
        else:
            if self.subsession.treatment == Constants.baseline:
                return False
            else:
                if self.player.group.approbation_group:
                    return False
                else:
                    if not self.player.dictator:
                        return False
        return True

    def vars_for_template(self):
        return self.player.vars_for_template()

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        self.group.set_extraction_applied()


class BeforeResults(WaitPage):
    body_text = _("En attente des autres participants")
    wait_for_all_groups = True
    after_all_players_arrive = "compute_payoffs"


class Results(Page):
    def vars_for_template(self):
        existing = self.player.vars_for_template()
        existing.update(dict(
            other_1=self.player.get_others_in_group()[0].extraction,
            other_2=self.player.get_others_in_group()[1].extraction,
            other_1_payoff=self.player.get_others_in_group()[0].payoff,
            other_2_payoff=self.player.get_others_in_group()[1].payoff
        ))
        return existing

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))

    def before_next_page(self):
        if self.round_number == Constants.num_rounds:
            self.player.compute_final_payoff()


class ResultsWaitForAll(WaitPage):
    body_text = _("En attente des autres participants")
    wait_for_all_groups = True


class Final(Page):
    def is_displayed(self):
        return self.round_number == Constants.round_second_part - 1 or self.round_number == Constants.num_rounds

    def vars_for_template(self):
        return self.player.vars_for_template()

    def js_vars(self):
        return dict(fill_auto=self.session.config.get("fill_auto", False))


page_sequence = [
    Presentation,
    Instructions, InstructionsWaitMonitor, Understanding, UnderstandingResults, UnderstandingResultsWaitForAll,
    Extraction, ExtractionWaitForAll,
    Approbation, ApprobationWaitForAll, ApprobationResults, ExtractionDictator,
    BeforeResults, Results, ResultsWaitForAll,
    Final
]
