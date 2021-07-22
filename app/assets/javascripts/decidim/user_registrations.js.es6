$(() => {
    const $userRegistrationForm = $("#register-form");
    const $userGroupFields = $userRegistrationForm.find(".user-group-fields");
    const inputSelector = "input[name='user[sign_up_as]']";
    const $formStepForwardButton = $(".form-step-forward-button");
    const $formStepBackButton = $(".form-step-back-button");
    const $formFirstStepFields = $("[form-step='1'] input");
    const $tosAgreement = $("#registration_user_tos_agreement");
    const $mandatoryFormFirstStepFields = $formFirstStepFields.not("#registration_user_newsletter").not("input[type ='hidden']").add($tosAgreement);
    const $userPassword = $("#registration_user_password");
    const $userPasswordConfirmation = $("#registration_user_password_confirmation");
    const $userLivingArea = $("#registration_user_living_area");
    const $cityLivingArea = $(".city_living_area");
    const $metropolisLivingArea = $(".metropolis_living_area");
    const $railsValidationAsterisk = $("[for=\"registration_user_living_area\"]").children("span.label-required").clone()

    const $underageSelector = $("#registration_underage_registration");
    const $statutoryRepresentativeEmailSelector = $("#statutory_representative_email");

    const emailSelectorToggle = () => {
        if ($underageSelector.is(":checked")) {
            $statutoryRepresentativeEmailSelector.removeClass("hide");
        } else {
            $statutoryRepresentativeEmailSelector.addClass("hide");
        }
    };

    if ($underageSelector.is(":checked")) {
        emailSelectorToggle();
    }

    $underageSelector.on("click", () => {
        emailSelectorToggle();
    });

    const userLivingAreaToggle = () => {
        addValidationAsterisk($userLivingArea.val())

        if ($userLivingArea.val() === "city") {
            $cityLivingArea.show();
            $metropolisLivingArea.hide();
        } else if ($userLivingArea.val() === "metropolis") {
            $cityLivingArea.hide();
            $metropolisLivingArea.show();
        } else {
            $cityLivingArea.hide();
            $metropolisLivingArea.hide();
        }
    };

    // Clone rails validator asterisk and add before the selector
    const addValidationAsterisk = (selector) => {
        const $element = $(`#registration_user_${selector}_residential_area`);

        if ( $element.length && $element.parent().children("span.label-required").length <= 0) {
            $element.before($railsValidationAsterisk);
        }
    }
    const setGroupFieldsVisibility = (value) => {
        if (value === "user") {
            $userGroupFields.hide();
        } else {
            $userGroupFields.show();
        }
    };

    const toggleFromSteps = () => {
        $("[form-step]").toggle();
        $("[form-active-step]").toggleClass("step--active");
    };

    const scrollToTop = () => {
        $("html, body").animate({
            scrollTop: $("main").offset().top
        }, 200);
    };

    userLivingAreaToggle();
    setGroupFieldsVisibility($userRegistrationForm.find(`${inputSelector}:checked`).val());

    $userRegistrationForm.on("change", inputSelector, (event) => {
        const value = event.target.value;

        setGroupFieldsVisibility(value);
    });

    $formStepForwardButton.on("click", (event) => {
        event.preventDefault();

        scrollToTop();

        // validate only input elements from step 1
        $formFirstStepFields.each((index, element) => {
            $userRegistrationForm.foundation("validateInput", $(element));
        });

        if (!$userRegistrationForm.find("[data-invalid]:visible").length) {
            toggleFromSteps();
        }
    });

    $formStepBackButton.on("click", (event) => {
        event.preventDefault();

        scrollToTop();

        toggleFromSteps();
    });

    let fieldEmptyOrFalse = (element) => {
        if ($(element)[0].type === "checkbox") {
            return $(element)[0].checked === false;
        }
        return $(element).val().length === 0;
    };

    let filledMandatoryFormField = () => {
        return $mandatoryFormFirstStepFields.map((index, element) => {
            if (fieldEmptyOrFalse(element)) {
                return element;
            }
            return null
        });
    };

    let samePassword = () => {
        if ($userPassword.val() !== $userPasswordConfirmation.val()) {
            return $userPasswordConfirmation;
        }
        return null;
    };

    const checkMandatoryFormField = () => {
        return $.uniqueSort(filledMandatoryFormField().add(samePassword()))
    };

    const displayError = (element) => {
        $(element).addClass("is-invalid-input");
        $(element).parent().addClass("is-invalid-label");
        $(element).next("span").addClass("is-visible");
    };

    $userRegistrationForm.on("click load change input", () => {
        checkMandatoryFormField().each((index, element) => {
            displayError(element);
        });

        userLivingAreaToggle();

        $formStepForwardButton.attr("disabled", (checkMandatoryFormField().length > 0));
    });
});
