#if defined _menu_stocks_included_
  #endinput
#endif
#define _menu_stocks_included_ "1.0"

#include <menus>

stock PushMenuString(Handle:hndl, const String:id[], const String:data[])
{
	AddMenuItem(hndl, id, data, ITEMDRAW_IGNORE);
}

stock PushMenuCell(Handle:hndl, const String:id[], data)
{
	decl String:DataString[64];
	IntToString(data, DataString, sizeof(DataString));
	AddMenuItem(hndl, id, DataString, ITEMDRAW_IGNORE);
}

stock PushMenuFloat(Handle:hndl, const String:id[], Float:data)
{
	decl String:DataString[64];
	FloatToString(data, DataString, sizeof(DataString));
	AddMenuItem(hndl, id, DataString, ITEMDRAW_IGNORE);
}

stock bool:GetMenuString(Handle:hndl, const String:id[], String:Buffer[], size)
{
	new ItemCount = GetMenuItemCount(hndl);
	decl String:info[64], String:data[64];
	
	for (new i = 0; i < ItemCount; i++) {
		GetMenuItem(hndl, i, info, sizeof(info), _, data, sizeof(data));
		
		if (StrEqual(info, id)) {	
			strcopy(Buffer, size, data);
			return true;
		}
	}	
	return false;
}

stock GetMenuCell(Handle:hndl, const String:id[], DefaultValue = 0)
{
	new ItemCount = GetMenuItemCount(hndl);
	decl String:info[64], String:data[64];
	
	for (new i = 0; i < ItemCount; i++) {
		GetMenuItem(hndl, i, info, sizeof(info), _, data, sizeof(data));
		
		if (StrEqual(info, id))
			return StringToInt(data);
	}	
	return DefaultValue;
}

stock Float:GetMenuFloat(Handle:hndl, const String:id[], Float:DefaultValue = 0.0)
{
	new ItemCount = GetMenuItemCount(hndl);
	decl String:info[64], String:data[64];
	
	for (new i = 0; i < ItemCount; i++) {
		GetMenuItem(hndl, i, info, sizeof(info), _, data, sizeof(data));
		
		if (StrEqual(info, id))
			return StringToFloat(data);
	}	
	return DefaultValue;
}

stock CopyMenuAny(Handle:source, Handle:dest, const String:id[])
{
	new ItemCount = GetMenuItemCount(source);
	decl String:info[64], String:data[64];
	
	for (new i = 0; i < ItemCount; i++) {
		GetMenuItem(source, i, info, sizeof(info), _, data, sizeof(data));
		
		if (StrEqual(info, id))
			AddMenuItem(dest, id, data, ITEMDRAW_IGNORE);
	}
}

stock bool:AddMenuItemFormat(&Handle:menu, const String:info[], style = ITEMDRAW_DEFAULT, const String:format[], any:...)
{
	decl String:display[128];
	VFormat(display, sizeof(display), format, 5);
	
	return bool:AddMenuItem(menu, info, display, style);
}
