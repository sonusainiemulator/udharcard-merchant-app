
class ProfileModel {
    Message? message;

    ProfileModel({
        this.message,
    });

    factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        message: json["message"] == null ? null : Message.fromJson(json["message"]),
    );

   
}

class Message {
    Profile? userProfile;
    List<Wallet>? wallets;
    List<Language>? languages;
    List<Country>? countries;

    Message({
        this.userProfile,
        this.wallets,
        this.languages,
        this.countries,
    });

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        userProfile: json["userProfile"] == null ? null : Profile.fromJson(json["userProfile"]),
        wallets: json["wallets"] == null ? [] : List<Wallet>.from(json["wallets"]!.map((x) => Wallet.fromJson(x))),
        languages: json["languages"] == null ? [] : List<Language>.from(json["languages"]!.map((x) => Language.fromJson(x))),
        countries: json["countries"] == null ? [] : List<Country>.from(json["countries"]!.map((x) => Country.fromJson(x))),
    );

  
}

class User {
    dynamic id;
    dynamic username;
    dynamic languageId;
    dynamic mobile;
    Profile? profile;

    User({
        this.id,
        this.username,
        this.languageId,
        this.mobile,
        this.profile,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
        languageId: json["language_id"],
        mobile: json["mobile"],
        profile: json["profile"] == null ? null : Profile.fromJson(json["profile"]),
    );

   
}

class Profile {
    dynamic id;
    dynamic username;
    dynamic languageId;
    dynamic firstname;
    dynamic lastname;
    dynamic email;
    dynamic imageDriver;
    dynamic image;
    dynamic name;
    dynamic phone;
    dynamic phoneCode;
    dynamic city;
    dynamic state;
    dynamic address_one;
    dynamic profilePicture;
    dynamic lastSeenActivity;
    dynamic created_at;
    dynamic shopName;
    dynamic businessName;
    dynamic businessType;
    dynamic isShopOnline;
    dynamic shopOpeningTime;
    dynamic shopClosingTime;
    dynamic shopClosedDays;
    dynamic landmark;
    dynamic whatsappNumber;
    dynamic shopDescription;
    dynamic gstNumber;
    dynamic panNumber;
    dynamic zipCode;

    Profile({
        this.id,
        this.username,
        this.languageId,
        this.firstname,
        this.lastname,
        this.email,
        this.imageDriver,
        this.image,
        this.name,
        this.profilePicture,
        this.lastSeenActivity,
        this.created_at,
        this.phone,
        this.phoneCode,
        this.city,
        this.state,
        this.address_one,
        this.shopName,
        this.businessName,
        this.businessType,
        this.isShopOnline,
        this.shopOpeningTime,
        this.shopClosingTime,
        this.shopClosedDays,
        this.landmark,
        this.whatsappNumber,
        this.shopDescription,
        this.gstNumber,
        this.panNumber,
        this.zipCode,
    });

    factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json["id"],
        username: json["username"],
        languageId: json["language_id"] ?? "1",
        firstname: json["firstname"],
        lastname: json["lastname"],
        email: json["email"],
        imageDriver: json["image_driver"],
        image: json["image"],
        name: json["name"],
        phoneCode: json["phone_code"],
        phone: json["phone"],
        city: json["city"],
        state: json["state"],
        address_one: json["address_one"],
        created_at: json["created_at"],
        profilePicture: json["profile_picture"],
        lastSeenActivity: json["last-seen-activity"],
        shopName: json["shop_name"] ?? json["business_name"],
        businessName: json["business_name"],
        businessType: json["business_type"],
        isShopOnline: json["is_shop_online"] == null
            ? true
            : (json["is_shop_online"] == true ||
                json["is_shop_online"] == 1 ||
                json["is_shop_online"].toString() == "1" ||
                json["is_shop_online"].toString().toLowerCase() == "true"),
        shopOpeningTime: json["shop_opening_time"] ?? "09:00 AM",
        shopClosingTime: json["shop_closing_time"] ?? "09:30 PM",
        shopClosedDays: json["shop_closed_days"] ?? "Open All Days",
        landmark: json["landmark"],
        whatsappNumber: json["whatsapp_number"],
        shopDescription: json["shop_description"],
        gstNumber: json["gst_number"],
        panNumber: json["pan_number"],
        zipCode: json["zip_code"],
    );

}

class Wallet {
    dynamic id;
    dynamic userId;
    dynamic currencyId;
    dynamic balance;
    dynamic isActive;
    dynamic isDefault;
    dynamic createdAt;
    dynamic updatedAt;
    dynamic logo;
    Currency? currency;

    Wallet({
        this.id,
        this.userId,
        this.currencyId,
        this.balance,
        this.isActive,
        this.isDefault,
        this.createdAt,
        this.updatedAt,
        this.logo,
        this.currency,
    });

    factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json["id"],
        userId: json["user_id"],
        currencyId: json["currency_id"],
        balance: json["balance"],
        isActive: json["is_active"],
        isDefault: json["is_default"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        logo: json["logo"],
        currency: json["currency"] == null ? null : Currency.fromJson(json["currency"]),
    );

}

class Currency {
    dynamic id;
    dynamic name;
    dynamic symbol;
    dynamic code;
    dynamic logo;
    dynamic exchangeRate;
    dynamic isActive;
    dynamic currencyType;
    dynamic createdAt;
    dynamic updatedAt;

    Currency({
        this.id,
        this.name,
        this.symbol,
        this.code,
        this.logo,
        this.exchangeRate,
        this.isActive,
        this.currencyType,
        this.createdAt,
        this.updatedAt,
    });

    factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        id: json["id"],
        name: json["name"],
        symbol: json["symbol"],
        code: json["code"],
        logo: json["logo"],
        exchangeRate: json["exchange_rate"],
        isActive: json["is_active"],
        currencyType: json["currency_type"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    );


}

class Language {
    dynamic id;
    dynamic name;

    Language({
        this.id,
        this.name,
    });

    factory Language.fromJson(Map<String, dynamic> json) => Language(
        id: json["id"],
        name: json["name"],
    );

   
}

class Country {
    dynamic name;
    dynamic code;
    dynamic phoneCode;
    dynamic isoCode;

    Country({
        this.name,
        this.code,
        this.phoneCode,
        this.isoCode,
    });

    factory Country.fromJson(Map<String, dynamic> json) => Country(
        name: json["name"],
        code: json["code"],
        phoneCode: json["phone_code"],
        isoCode: json["iso_code"],
    );

}
