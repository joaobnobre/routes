let mainBg = document.getElementById('mainBg');
mainBg.style.display = 'none';
let promptBg = document.getElementById('promptBackground');
promptBg.style.display = 'none';

let selectedItemss = [[],[]]; // 0 = coleta, 1 = entrega
loadLeftCards = function(data){
    $('.leftCards').remove();
    $('#leftSide').append('<div class="leftCards"></div>');    

    let receivableItems = data[0];
    let deliverableItems = data[1];
    selectedItemss = [[],[]];

    for (let index = 0; index < receivableItems.length; index++) {
        $('.leftCards').append(`<div class="receivableCard" id="${'receivable-'+receivableItems[index]}" style="background-image: url('${imgsDir}/${receivableItems[index]}.png')">${receivableItems[index]}</div>`);    
        
        document.getElementById('receivable-'+receivableItems[index]).onclick = function() {
            if (selectedItemss[0][receivableItems[index]]) {
                selectedItemss[0][receivableItems[index]] = false;
                $("#receivable-"+receivableItems[index]).css("outline", "none");
            }else{
                selectedItemss[0][receivableItems[index]] = true;
                $("#receivable-"+receivableItems[index]).css("outline", "2px solid #6851ffd5");
            };
        };
    };

    for (let index = 0; index < deliverableItems.length; index++) {
        $('.leftCards').append(`<div class="deliverableCard" id="${'deliverable-'+deliverableItems[index]}" style="display:none;background-image: url('${imgsDir}/${deliverableItems[index]}.png')">${deliverableItems[index]}</div>`);    
    
        document.getElementById('deliverable-'+deliverableItems[index]).onclick = function() {
            if (!selectedItemss[1][deliverableItems[index]]) {
                selectedItemss[1][deliverableItems[index]] = true;
                $("#deliverable-"+deliverableItems[index]).css("outline", "2px solid #6851ffd5");
            }else{
                selectedItemss[1][deliverableItems[index]] = false;
                $("#deliverable-"+deliverableItems[index]).css("outline", "none");
            };
        };
    };
;}

showNui = function() {
    mainBg.style.display = 'flex';

    $("#coletaButton").css("box-shadow", "0px 0px 10px 1px rgba(0, 0, 0, 0.12)");
    $("#coletaButton").css("background", "linear-gradient(180deg, #9D51FF 0%, #6951FF 100%)");
    $("#coletaButton").css("border-radius", "12px");
    $("#coletaButton").css("color", "white");

    $('#entregaButton').css('box-shadow','none');
    $('#entregaButton').css('background','transparent');
    $('#entregaButton').css('color','#B2B3BB');

    $('#soloButton').css('box-shadow','0px 0px 10px 1px rgba(0, 0, 0, 0.12)');
    $('#soloButton').css('background','linear-gradient(180deg, #9D51FF 0%, #6951FF 100%)');
    $('#soloButton').css('border-radius','12px');
    $('#soloButton').css('color','white');

    $('#lobbyButton').css('box-shadow','none');
    $('#lobbyButton').css('background','transparent');
    $('#lobbyButton').css('color','#B2B3BB');

    document.getElementById('startButton').innerHTML = 'INICIAR SOLO';
};

let onPrompt = false;
showPrompt = function(promptInfo) {
    onPrompt = true
    setTimeout(() => {
        onPrompt = false
        document.getElementById('promptContainer').innerHTML = 'Nenhum convite para rota em grupo pendente.';
        promptBg.style.display = 'none';
    }, 15000);

    document.getElementById('promptContainer').innerHTML = promptInfo[0]+' te convidou para rota em grupo';
    promptBg.style.display = 'flex';
};

closePrompt = function() {
    onPrompt = false
    document.getElementById('promptContainer').innerHTML = 'Nenhum convite para rota em grupo pendente.';
    promptBg.style.display = 'none';
};

window.addEventListener("message", function(event){
    if (event.data.onNui != undefined && !event.data.onPrompt) {
        if (event.data.onNui && event.data.arrayData != undefined) {
            showNui();
            routeTypes[0] = 0;
            routeTypes[1] = 0;
            loadLeftCards(event.data.arrayData)
            $('.inviteCard').remove();
        }else{
            mainBg.style.display = 'none';
        }
    };

    if (!event.data.onNui && event.data.onPrompt){
        if (!onPrompt) {
            showPrompt(event.data.onPrompt);
        }
    };

    if (!event.data.onNui && !event.data.onPrompt && event.data.closingPrompt){
        if (onPrompt) {
            closePrompt();
        }
    };
});

document.onkeyup = function(data) {
    if (data.which == 27) {
        $.post(`https://${GetParentResourceName()}/closeGui`, JSON.stringify({}));
    }
};


let selectedItems = ['maconha','mochila'];
let routeTypes = [] // routeTypes[1] = coleta (0) ou entrega (1); routeTypes[2] = solo (0) ou lobby (1)
document.getElementById('startButton').onclick = function() {
    $.post(`https://${GetParentResourceName()}/beginRoute`, JSON.stringify({selectedItems,routeTypes}));
};  

coletaButtonClick = function() {
    routeTypes[0] = 0;

    let coletaButton = document.getElementById('coletaButton');
    coletaButton.style.color = 'white';
    coletaButton.style.boxShadow = '0px 0px 10px 1px rgba(0, 0, 0, 0.12)';
    coletaButton.style.background = 'linear-gradient(180deg, #9D51FF 0%, #6951FF 100%)';
    coletaButton.style.borderRadius = '12px';
    
    let entregaButton = document.getElementById('entregaButton');
    entregaButton.style.color = '#B2B3BB';
    entregaButton.style.boxShadow = 'none';
    entregaButton.style.background = 'transparent';

    $(".receivableCard").css("display", "flex");
    $(".deliverableCard").css("display", "none");
}
document.getElementById('coletaButton').onclick = coletaButtonClick;

entregaButtonClick = function() {
    routeTypes[0] = 1;

    let entregaButton = document.getElementById('entregaButton');
    entregaButton.style.color = 'white';
    entregaButton.style.boxShadow = '0px 0px 10px 1px rgba(0, 0, 0, 0.12)';
    entregaButton.style.background = 'linear-gradient(180deg, #9D51FF 0%, #6951FF 100%)';
    entregaButton.style.borderRadius = '12px';
    
    let coletaButton = document.getElementById('coletaButton');
    coletaButton.style.color = '#B2B3BB';
    coletaButton.style.boxShadow = 'none';
    coletaButton.style.background = 'transparent';

    $(".receivableCard").css("display", "none");
    $(".deliverableCard").css("display", "flex");
}
document.getElementById('entregaButton').onclick = entregaButtonClick;

soloButtonClick = function() {
    routeTypes[1] = 0;
    $('.inviteCard').remove();

    let soloButton = document.getElementById('soloButton');
    soloButton.style.color = 'white';
    soloButton.style.boxShadow = '0px 0px 10px 1px rgba(0, 0, 0, 0.12)';
    soloButton.style.background = 'linear-gradient(180deg, #9D51FF 0%, #6951FF 100%)';
    soloButton.style.borderRadius = '12px';
    
    let lobbyButton = document.getElementById('lobbyButton');
    lobbyButton.style.color = '#B2B3BB';
    lobbyButton.style.boxShadow = 'none';
    lobbyButton.style.background = 'transparent';

    $('.inviteCard').css('display','none');
    $('.inviteCard').css('display','none');

    let startButton = document.getElementById('startButton');
    startButton.innerHTML = 'INICIAR SOLO';
}
document.getElementById('soloButton').onclick = soloButtonClick;

lobbyButtonClick = function() {
    routeTypes[1] = 1;
    loadInviteCards();

    let lobbyButton = document.getElementById('lobbyButton');
    lobbyButton.style.color = 'white';
    lobbyButton.style.boxShadow = '0px 0px 10px 1px rgba(0, 0, 0, 0.12)';
    lobbyButton.style.background = 'linear-gradient(180deg, #9D51FF 0%, #6951FF 100%)';
    lobbyButton.style.borderRadius = '12px';
    
    let soloButton = document.getElementById('soloButton');
    soloButton.style.color = '#B2B3BB';
    soloButton.style.boxShadow = 'none';
    soloButton.style.background = 'transparent';

    let startButton = document.getElementById('startButton');
    startButton.innerHTML = 'INICIAR LOBBY';
}
document.getElementById('lobbyButton').onclick = lobbyButtonClick;

loadInviteCards = function() {
    $('.inviteCard').remove();
    fetch(`https://${GetParentResourceName()}/loadInviteCards`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(resp => reloadInviteCards(resp));
}

let translateResponse = function(response,playerSrc){
    if (response){
        document.getElementById(`inviteCardButton0${playerSrc}`).innerHTML = 'CONVIDADO';
    }
};

reloadInviteCards = function(ids) {
    for (let element in ids) {
        $('#rightRec').append(`<div class="inviteCard" id="inviteCard0${ids[element][0]}">${ids[element][1]} <button class="inviteCardButton" id="inviteCardButton0${ids[element][0]}">Convidar</button>`);  
        document.getElementById(`inviteCard0${ids[element][0]}`).onclick = function() {
            if (document.getElementById(`inviteCardButton0${ids[element][0]}`).innerHTML != 'CONVIDADO') {
                let elemento = ids[element][0]
                fetch(`https://${GetParentResourceName()}/sendGroupInvite`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({elemento})
                }).then(resp => resp.json()).then(resp => translateResponse(resp,elemento));
            }
        };
    };
};