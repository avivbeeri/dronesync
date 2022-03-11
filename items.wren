import "core/dataobject" for DataObject

var Items = {
  "drone": {
    "id": "drone",
    "displayName": "drone",
    "range": 1,
    "splash": 0,
    "useCenter": false,
    "binary": true,
    "eternal": true
  },
  "smokebomb":    {
    "id": "smokebomb",
    "displayName": "smoke bomb",
    "range": 4,
    "splash": 4
  },
  "coin":   {
    "id": "coin",
    "displayName": "coin",
    "range": 10,
    "splash": 4
  }
}

class ItemFactory {
  static get(id) { get(id, 1) }
  static get(id, quantity) {
    var item = DataObject.copyValue(Items[id])
    item["quantity"] = quantity
    return item
  }

}
