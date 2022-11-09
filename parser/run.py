import json
from get_upcoming_items import get_upcoming_items
from get_released_items import get_released_items
from get_to_be_released_items import get_to_be_released_items
from get_release_date_for_item import get_release_date_for_item


if __name__ == '__main__':
    upcoming_items = get_upcoming_items() # upcoming 탭의 모든 아이템
    released_items = get_released_items(upcoming_items) # 출시된
    to_be_released_items = get_to_be_released_items(upcoming_items) # 출시 예정

    for item in to_be_released_items:
        date = get_release_date_for_item(item['href'])
        item['releaseDate'] = date

    #for upcoming_item in upcoming_items:
    #    print(upcoming_item)
    
    print("👟 출시된 아이템들")
    for released_item in released_items:
        print(released_item)
    
    print("👟 출시예정인 아이템들")
    for to_be_released_item in to_be_released_items:
        print(to_be_released_item)

    with open('../models/nike/released_items.json', 'w') as file:
        print("📝 released_items.json")
        json.dump(released_items, file, indent=4, ensure_ascii= False)
        file.write('\n')

    with open('../models/nike/to_be_released_items.json', 'w') as file:
        print("📝 to_be_released_items.json")
        json.dump(to_be_released_items, file, indent=4, ensure_ascii= False)
        file.write('\n')

