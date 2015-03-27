/*
 * Author: eRazeri and esteldunedain
 * Attach an item to the unit
 *
 * Arguments:
 * 0: vehicle that it will be attached to (player or vehicle) <OBJECT>
 * 1: unit doing the attach (player) <OBJECT>
 * 2: Array containing a string of the attachable item <ARRAY>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * Nothing
 *
 * Public: No
 */
#include "script_component.hpp"

PARAMS_3(_attachToVehicle,_unit,_args);

private ["_itemClassname", "_itemVehClass", "_onAtachText", "_selfAttachPosition", "_attachedItem", "_tempObject", "_actionID"];

_itemClassname = [_args, 0, ""] call CBA_fnc_defaultParam;

//Sanity Check (_unit has item in inventory, not over attach limit)
if ((_itemClassname == "") || {!(_this call FUNC(canAttach))}) exitWith {ERROR("Tried to attach, but check failed");};

_itemVehClass = "";
_onAtachText = "";
_selfAttachPosition = [_unit, [-0.05, 0, 0.12], "rightshoulder"];

switch (true) do {
case (_itemClassname == "ACE_IR_Strobe_Item"): {
        _itemVehClass = "ACE_IR_Strobe_Effect";
        _onAtachText = localize "STR_ACE_Attach_IrStrobe_Attached";
        //_selfAttachPosition = [_unit, [0, -0.11, 0.16], "pilot"];  //makes it attach to the head a bit better, shoulder is not good for visibility - eRazeri
    };
case (_itemClassname == "B_IR_Grenade"): {
        _itemVehClass = "B_IRStrobe";
        _onAtachText = localize "STR_ACE_Attach_IrGrenade_Attached";
    };
case (_itemClassname == "O_IR_Grenade"): {
        _itemVehClass = "O_IRStrobe";
        _onAtachText = localize "STR_ACE_Attach_IrGrenade_Attached";
    };
case (_itemClassname == "I_IR_Grenade"): {
        _itemVehClass = "I_IRStrobe";
        _onAtachText = localize "STR_ACE_Attach_IrGrenade_Attached";
    };
case (toLower _itemClassname in ["chemlight_blue", "chemlight_green", "chemlight_red", "chemlight_yellow"]): {
        _itemVehClass = _itemClassname;
        _onAtachText = localize "STR_ACE_Attach_Chemlight_Attached";
    };
};

if (_itemVehClass == "") exitWith {ERROR("no _itemVehClass for Item");};

if (_unit == _attachToVehicle) then {  //Self Attachment
    _unit removeItem _itemClassname;  // Remove item
    _attachedItem = _itemVehClass createVehicle [0,0,0];
    _attachedItem attachTo _selfAttachPosition;
    [_onAtachText] call EFUNC(common,displayTextStructured);
    _attachToVehicle setVariable [QGVAR(Objects), [_attachedItem], true];
    _attachToVehicle setVariable [QGVAR(ItemNames), [_itemClassname], true];
} else {
    GVAR(placeAction) = -1;

    _tempObject = _itemVehClass createVehicleLocal [0,0,-10000];
    _tempObject enableSimulationGlobal false;

    [_unit, QGVAR(vehAttach), true] call EFUNC(common,setForceWalkStatus);

    //MenuBack isn't working for now (localize "STR_ACE_Attach_CancelAction")
    [{[localize "STR_ACE_Attach_PlaceAction", ""] call EFUNC(interaction,showMouseHint)}, [], 0, 0] call EFUNC(common,waitAndExecute);
    _unit setVariable [QGVAR(placeActionEH), [_unit, "DefaultAction", {true}, {GVAR(placeAction) = 1;}] call EFUNC(common,AddActionEventHandler)];
    // _unit setVariable [QGVAR(cancelActionEH), [_unit, "MenuBack", {true}, {GVAR(placeAction) = 0;}] call EFUNC(common,AddActionEventHandler)];

    _actionID = _unit addAction [format ["<t color='#FF0000'>%1</t>", localize "STR_ACE_Attach_CancelAction"], {GVAR(placeAction) = 0}];
    
    [{
        PARAMS_2(_args,_pfID);
        EXPLODE_7_PVT(_args,_unit,_attachToVehicle,_itemClassname,_itemVehClass,_tempObject,_onAtachText,_actionID);

        if ((GVAR(placeAction) != -1) ||
                {_unit != ACE_player} ||
                {!([_unit, _attachToVehicle, []] call EFUNC(common,canInteractWith))} ||
                {!([_attachToVehicle, _unit, _itemClassname] call FUNC(canAttach))}) then {

            [_pfID] call CBA_fnc_removePerFrameHandler;
            [_unit, QGVAR(vehAttach), false] call EFUNC(common,setForceWalkStatus);
            [] call EFUNC(interaction,hideMouseHint);
            [_unit, "DefaultAction", (_unit getVariable [QGVAR(placeActionEH), -1])] call EFUNC(common,removeActionEventHandler);
            //[_unit, "MenuBack", (_unit getVariable [QGVAR(cancelActionEH), -1])] call EFUNC(common,removeActionEventHandler);
            _unit removeAction _actionID;
        
            if (GVAR(placeAction) == 1) then {
                _startingPosition = _tempObject modelToWorld [0,0,0];
                [_unit, _attachToVehicle, _itemClassname, _itemVehClass, _onAtachText, _startingPosition] call FUNC(placeApprove);
            };
            deleteVehicle _tempObject;
        } else {
            _tempObject setPosATL ((ASLtoATL eyePos _unit) vectorAdd (positionCameraToWorld [0,0,1] vectorDiff positionCameraToWorld [0,0,0]));;
        };
    }, 0, [_unit, _attachToVehicle, _itemClassname, _itemVehClass, _tempObject, _onAtachText, _actionID]] call CBA_fnc_addPerFrameHandler;
};
