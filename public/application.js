
function updateDealerDisplay() {
    $('#dealer_cards').load('/display/dealer_cards');
    $('#dealer_total').load('/display/dealer_total');
}

function updatePlayerDisplay() {
    $('#player_cards').load('/display/player_cards');
    $('#player_total').load('/display/player_total');
    $('#player_info').load('/display/player_info');
    $('#action_buttons').load('/display/action_buttons');
}

function updateAlerts() {
    $('#alert_message').load('/display/alert_message');
    $('#result_message').load('/display/result_message');
}

function runGame() {
    $.get('/run_game').done(function() {
        updateAlerts();
        updateDealerDisplay();
        updatePlayerDisplay();
    });
}

$(document).ready(function() {

    runGame();

    $(document).on('click', '#button_hit', function() {
        $.get('/hit').done(function() {
            runGame();
        });
        return false;
    });

    $(document).on('click', '#button_stay', function() {
        $.get('/stay').done(function() {
            runGame();
        });
        return false;
    });

    $(document).on('click', '#button_deal', function() {
        $.get('/deal').done(function() {
            runGame();
        });
        return false;
    });

});