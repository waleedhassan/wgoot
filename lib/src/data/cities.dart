import 'package:adhan/adhan.dart';

import '../core/utils/arabic_text.dart';
import 'models/city.dart';

const List<City> kCities = <City>[
  // السعودية
  City(id: 'sa-makkah', name: 'مكة المكرمة', country: 'السعودية', countryCode: 'SA', latitude: 21.4225, longitude: 39.8262, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-madinah', name: 'المدينة المنورة', country: 'السعودية', countryCode: 'SA', latitude: 24.4686, longitude: 39.6142, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-riyadh', name: 'الرياض', country: 'السعودية', countryCode: 'SA', latitude: 24.7136, longitude: 46.6753, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-jeddah', name: 'جدة', country: 'السعودية', countryCode: 'SA', latitude: 21.4858, longitude: 39.1925, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-dammam', name: 'الدمام', country: 'السعودية', countryCode: 'SA', latitude: 26.4207, longitude: 50.0888, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-taif', name: 'الطائف', country: 'السعودية', countryCode: 'SA', latitude: 21.2703, longitude: 40.4158, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-buraydah', name: 'بريدة', country: 'السعودية', countryCode: 'SA', latitude: 26.3260, longitude: 43.9750, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-tabuk', name: 'تبوك', country: 'السعودية', countryCode: 'SA', latitude: 28.3835, longitude: 36.5662, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-abha', name: 'أبها', country: 'السعودية', countryCode: 'SA', latitude: 18.2164, longitude: 42.5053, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-hail', name: 'حائل', country: 'السعودية', countryCode: 'SA', latitude: 27.5114, longitude: 41.7208, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-najran', name: 'نجران', country: 'السعودية', countryCode: 'SA', latitude: 17.4924, longitude: 44.1277, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-jazan', name: 'جازان', country: 'السعودية', countryCode: 'SA', latitude: 16.8892, longitude: 42.5511, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-hofuf', name: 'الهفوف', country: 'السعودية', countryCode: 'SA', latitude: 25.3647, longitude: 49.5877, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-yanbu', name: 'ينبع', country: 'السعودية', countryCode: 'SA', latitude: 24.0895, longitude: 38.0618, timeZone: 'Asia/Riyadh'),
  City(id: 'sa-khamis', name: 'خميس مشيط', country: 'السعودية', countryCode: 'SA', latitude: 18.3000, longitude: 42.7300, timeZone: 'Asia/Riyadh'),

  // الإمارات
  City(id: 'ae-abudhabi', name: 'أبو ظبي', country: 'الإمارات', countryCode: 'AE', latitude: 24.4539, longitude: 54.3773, timeZone: 'Asia/Dubai'),
  City(id: 'ae-dubai', name: 'دبي', country: 'الإمارات', countryCode: 'AE', latitude: 25.2048, longitude: 55.2708, timeZone: 'Asia/Dubai'),
  City(id: 'ae-sharjah', name: 'الشارقة', country: 'الإمارات', countryCode: 'AE', latitude: 25.3463, longitude: 55.4209, timeZone: 'Asia/Dubai'),
  City(id: 'ae-alain', name: 'العين', country: 'الإمارات', countryCode: 'AE', latitude: 24.1302, longitude: 55.8023, timeZone: 'Asia/Dubai'),
  City(id: 'ae-rak', name: 'رأس الخيمة', country: 'الإمارات', countryCode: 'AE', latitude: 25.7895, longitude: 55.9432, timeZone: 'Asia/Dubai'),
  City(id: 'ae-ajman', name: 'عجمان', country: 'الإمارات', countryCode: 'AE', latitude: 25.4052, longitude: 55.5136, timeZone: 'Asia/Dubai'),
  City(id: 'ae-fujairah', name: 'الفجيرة', country: 'الإمارات', countryCode: 'AE', latitude: 25.1288, longitude: 56.3265, timeZone: 'Asia/Dubai'),

  // الكويت وقطر والبحرين وعُمان
  City(id: 'kw-kuwait', name: 'مدينة الكويت', country: 'الكويت', countryCode: 'KW', latitude: 29.3759, longitude: 47.9774, timeZone: 'Asia/Kuwait'),
  City(id: 'qa-doha', name: 'الدوحة', country: 'قطر', countryCode: 'QA', latitude: 25.2854, longitude: 51.5310, timeZone: 'Asia/Qatar'),
  City(id: 'qa-rayyan', name: 'الريان', country: 'قطر', countryCode: 'QA', latitude: 25.2919, longitude: 51.4244, timeZone: 'Asia/Qatar'),
  City(id: 'bh-manama', name: 'المنامة', country: 'البحرين', countryCode: 'BH', latitude: 26.2285, longitude: 50.5860, timeZone: 'Asia/Bahrain'),
  City(id: 'bh-muharraq', name: 'المحرق', country: 'البحرين', countryCode: 'BH', latitude: 26.2572, longitude: 50.6119, timeZone: 'Asia/Bahrain'),
  City(id: 'om-muscat', name: 'مسقط', country: 'عُمان', countryCode: 'OM', latitude: 23.5880, longitude: 58.3829, timeZone: 'Asia/Muscat'),
  City(id: 'om-salalah', name: 'صلالة', country: 'عُمان', countryCode: 'OM', latitude: 17.0151, longitude: 54.0924, timeZone: 'Asia/Muscat'),
  City(id: 'om-sohar', name: 'صحار', country: 'عُمان', countryCode: 'OM', latitude: 24.3475, longitude: 56.7089, timeZone: 'Asia/Muscat'),
  City(id: 'om-nizwa', name: 'نزوى', country: 'عُمان', countryCode: 'OM', latitude: 22.9333, longitude: 57.5333, timeZone: 'Asia/Muscat'),

  // اليمن
  City(id: 'ye-sanaa', name: 'صنعاء', country: 'اليمن', countryCode: 'YE', latitude: 15.3694, longitude: 44.1910, timeZone: 'Asia/Aden'),
  City(id: 'ye-aden', name: 'عدن', country: 'اليمن', countryCode: 'YE', latitude: 12.7797, longitude: 45.0095, timeZone: 'Asia/Aden'),
  City(id: 'ye-taiz', name: 'تعز', country: 'اليمن', countryCode: 'YE', latitude: 13.5789, longitude: 44.0219, timeZone: 'Asia/Aden'),
  City(id: 'ye-hodeidah', name: 'الحديدة', country: 'اليمن', countryCode: 'YE', latitude: 14.7978, longitude: 42.9545, timeZone: 'Asia/Aden'),
  City(id: 'ye-mukalla', name: 'المكلا', country: 'اليمن', countryCode: 'YE', latitude: 14.5425, longitude: 49.1242, timeZone: 'Asia/Aden'),

  // مصر
  City(id: 'eg-cairo', name: 'القاهرة', country: 'مصر', countryCode: 'EG', latitude: 30.0444, longitude: 31.2357, timeZone: 'Africa/Cairo'),
  City(id: 'eg-alex', name: 'الإسكندرية', country: 'مصر', countryCode: 'EG', latitude: 31.2001, longitude: 29.9187, timeZone: 'Africa/Cairo'),
  City(id: 'eg-giza', name: 'الجيزة', country: 'مصر', countryCode: 'EG', latitude: 30.0131, longitude: 31.2089, timeZone: 'Africa/Cairo'),
  City(id: 'eg-portsaid', name: 'بورسعيد', country: 'مصر', countryCode: 'EG', latitude: 31.2653, longitude: 32.3019, timeZone: 'Africa/Cairo'),
  City(id: 'eg-suez', name: 'السويس', country: 'مصر', countryCode: 'EG', latitude: 29.9668, longitude: 32.5498, timeZone: 'Africa/Cairo'),
  City(id: 'eg-mansoura', name: 'المنصورة', country: 'مصر', countryCode: 'EG', latitude: 31.0409, longitude: 31.3785, timeZone: 'Africa/Cairo'),
  City(id: 'eg-tanta', name: 'طنطا', country: 'مصر', countryCode: 'EG', latitude: 30.7865, longitude: 31.0004, timeZone: 'Africa/Cairo'),
  City(id: 'eg-assiut', name: 'أسيوط', country: 'مصر', countryCode: 'EG', latitude: 27.1783, longitude: 31.1859, timeZone: 'Africa/Cairo'),
  City(id: 'eg-luxor', name: 'الأقصر', country: 'مصر', countryCode: 'EG', latitude: 25.6872, longitude: 32.6396, timeZone: 'Africa/Cairo'),
  City(id: 'eg-aswan', name: 'أسوان', country: 'مصر', countryCode: 'EG', latitude: 24.0889, longitude: 32.8998, timeZone: 'Africa/Cairo'),
  City(id: 'eg-ismailia', name: 'الإسماعيلية', country: 'مصر', countryCode: 'EG', latitude: 30.5965, longitude: 32.2715, timeZone: 'Africa/Cairo'),
  City(id: 'eg-sharm', name: 'شرم الشيخ', country: 'مصر', countryCode: 'EG', latitude: 27.9158, longitude: 34.3300, timeZone: 'Africa/Cairo'),

  // بلاد الشام
  City(id: 'ps-quds', name: 'القدس', country: 'فلسطين', countryCode: 'PS', latitude: 31.7683, longitude: 35.2137, timeZone: 'Asia/Hebron'),
  City(id: 'ps-gaza', name: 'غزة', country: 'فلسطين', countryCode: 'PS', latitude: 31.5017, longitude: 34.4668, timeZone: 'Asia/Gaza'),
  City(id: 'ps-ramallah', name: 'رام الله', country: 'فلسطين', countryCode: 'PS', latitude: 31.9038, longitude: 35.2034, timeZone: 'Asia/Hebron'),
  City(id: 'ps-hebron', name: 'الخليل', country: 'فلسطين', countryCode: 'PS', latitude: 31.5326, longitude: 35.0998, timeZone: 'Asia/Hebron'),
  City(id: 'ps-nablus', name: 'نابلس', country: 'فلسطين', countryCode: 'PS', latitude: 32.2211, longitude: 35.2544, timeZone: 'Asia/Hebron'),
  City(id: 'jo-amman', name: 'عمّان', country: 'الأردن', countryCode: 'JO', latitude: 31.9539, longitude: 35.9106, timeZone: 'Asia/Amman'),
  City(id: 'jo-irbid', name: 'إربد', country: 'الأردن', countryCode: 'JO', latitude: 32.5556, longitude: 35.8500, timeZone: 'Asia/Amman'),
  City(id: 'jo-zarqa', name: 'الزرقاء', country: 'الأردن', countryCode: 'JO', latitude: 32.0728, longitude: 36.0876, timeZone: 'Asia/Amman'),
  City(id: 'jo-aqaba', name: 'العقبة', country: 'الأردن', countryCode: 'JO', latitude: 29.5319, longitude: 35.0061, timeZone: 'Asia/Amman'),
  City(id: 'sy-damascus', name: 'دمشق', country: 'سوريا', countryCode: 'SY', latitude: 33.5138, longitude: 36.2765, timeZone: 'Asia/Damascus'),
  City(id: 'sy-aleppo', name: 'حلب', country: 'سوريا', countryCode: 'SY', latitude: 36.2021, longitude: 37.1343, timeZone: 'Asia/Damascus'),
  City(id: 'sy-homs', name: 'حمص', country: 'سوريا', countryCode: 'SY', latitude: 34.7324, longitude: 36.7137, timeZone: 'Asia/Damascus'),
  City(id: 'sy-hama', name: 'حماة', country: 'سوريا', countryCode: 'SY', latitude: 35.1318, longitude: 36.7578, timeZone: 'Asia/Damascus'),
  City(id: 'sy-latakia', name: 'اللاذقية', country: 'سوريا', countryCode: 'SY', latitude: 35.5317, longitude: 35.7915, timeZone: 'Asia/Damascus'),
  City(id: 'lb-beirut', name: 'بيروت', country: 'لبنان', countryCode: 'LB', latitude: 33.8938, longitude: 35.5018, timeZone: 'Asia/Beirut'),
  City(id: 'lb-tripoli', name: 'طرابلس', country: 'لبنان', countryCode: 'LB', latitude: 34.4367, longitude: 35.8497, timeZone: 'Asia/Beirut'),
  City(id: 'lb-saida', name: 'صيدا', country: 'لبنان', countryCode: 'LB', latitude: 33.5571, longitude: 35.3729, timeZone: 'Asia/Beirut'),

  // العراق
  City(id: 'iq-baghdad', name: 'بغداد', country: 'العراق', countryCode: 'IQ', latitude: 33.3152, longitude: 44.3661, timeZone: 'Asia/Baghdad'),
  City(id: 'iq-basra', name: 'البصرة', country: 'العراق', countryCode: 'IQ', latitude: 30.5085, longitude: 47.7804, timeZone: 'Asia/Baghdad'),
  City(id: 'iq-mosul', name: 'الموصل', country: 'العراق', countryCode: 'IQ', latitude: 36.3350, longitude: 43.1189, timeZone: 'Asia/Baghdad'),
  City(id: 'iq-erbil', name: 'أربيل', country: 'العراق', countryCode: 'IQ', latitude: 36.1911, longitude: 44.0092, timeZone: 'Asia/Baghdad'),
  City(id: 'iq-najaf', name: 'النجف', country: 'العراق', countryCode: 'IQ', latitude: 32.0000, longitude: 44.3350, timeZone: 'Asia/Baghdad'),
  City(id: 'iq-karbala', name: 'كربلاء', country: 'العراق', countryCode: 'IQ', latitude: 32.6160, longitude: 44.0242, timeZone: 'Asia/Baghdad'),
  City(id: 'iq-kirkuk', name: 'كركوك', country: 'العراق', countryCode: 'IQ', latitude: 35.4681, longitude: 44.3922, timeZone: 'Asia/Baghdad'),
  City(id: 'iq-sulaymaniyah', name: 'السليمانية', country: 'العراق', countryCode: 'IQ', latitude: 35.5556, longitude: 45.4351, timeZone: 'Asia/Baghdad'),

  // السودان وليبيا وتونس والجزائر والمغرب وموريتانيا
  City(id: 'sd-khartoum', name: 'الخرطوم', country: 'السودان', countryCode: 'SD', latitude: 15.5007, longitude: 32.5599, timeZone: 'Africa/Khartoum'),
  City(id: 'sd-omdurman', name: 'أم درمان', country: 'السودان', countryCode: 'SD', latitude: 15.6445, longitude: 32.4777, timeZone: 'Africa/Khartoum'),
  City(id: 'sd-portsudan', name: 'بورتسودان', country: 'السودان', countryCode: 'SD', latitude: 19.6158, longitude: 37.2164, timeZone: 'Africa/Khartoum'),
  City(id: 'ly-tripoli', name: 'طرابلس', country: 'ليبيا', countryCode: 'LY', latitude: 32.8872, longitude: 13.1913, timeZone: 'Africa/Tripoli'),
  City(id: 'ly-benghazi', name: 'بنغازي', country: 'ليبيا', countryCode: 'LY', latitude: 32.1167, longitude: 20.0667, timeZone: 'Africa/Tripoli'),
  City(id: 'ly-misrata', name: 'مصراتة', country: 'ليبيا', countryCode: 'LY', latitude: 32.3754, longitude: 15.0925, timeZone: 'Africa/Tripoli'),
  City(id: 'tn-tunis', name: 'تونس', country: 'تونس', countryCode: 'TN', latitude: 36.8065, longitude: 10.1815, timeZone: 'Africa/Tunis'),
  City(id: 'tn-sfax', name: 'صفاقس', country: 'تونس', countryCode: 'TN', latitude: 34.7406, longitude: 10.7603, timeZone: 'Africa/Tunis'),
  City(id: 'tn-sousse', name: 'سوسة', country: 'تونس', countryCode: 'TN', latitude: 35.8256, longitude: 10.6084, timeZone: 'Africa/Tunis'),
  City(id: 'tn-kairouan', name: 'القيروان', country: 'تونس', countryCode: 'TN', latitude: 35.6781, longitude: 10.0963, timeZone: 'Africa/Tunis'),
  City(id: 'dz-algiers', name: 'الجزائر', country: 'الجزائر', countryCode: 'DZ', latitude: 36.7538, longitude: 3.0588, timeZone: 'Africa/Algiers'),
  City(id: 'dz-oran', name: 'وهران', country: 'الجزائر', countryCode: 'DZ', latitude: 35.6969, longitude: -0.6331, timeZone: 'Africa/Algiers'),
  City(id: 'dz-constantine', name: 'قسنطينة', country: 'الجزائر', countryCode: 'DZ', latitude: 36.3650, longitude: 6.6147, timeZone: 'Africa/Algiers'),
  City(id: 'dz-annaba', name: 'عنابة', country: 'الجزائر', countryCode: 'DZ', latitude: 36.9000, longitude: 7.7667, timeZone: 'Africa/Algiers'),
  City(id: 'dz-batna', name: 'باتنة', country: 'الجزائر', countryCode: 'DZ', latitude: 35.5559, longitude: 6.1741, timeZone: 'Africa/Algiers'),
  City(id: 'ma-rabat', name: 'الرباط', country: 'المغرب', countryCode: 'MA', latitude: 34.0209, longitude: -6.8416, timeZone: 'Africa/Casablanca'),
  City(id: 'ma-casablanca', name: 'الدار البيضاء', country: 'المغرب', countryCode: 'MA', latitude: 33.5731, longitude: -7.5898, timeZone: 'Africa/Casablanca'),
  City(id: 'ma-marrakech', name: 'مراكش', country: 'المغرب', countryCode: 'MA', latitude: 31.6295, longitude: -7.9811, timeZone: 'Africa/Casablanca'),
  City(id: 'ma-fes', name: 'فاس', country: 'المغرب', countryCode: 'MA', latitude: 34.0181, longitude: -5.0078, timeZone: 'Africa/Casablanca'),
  City(id: 'ma-tangier', name: 'طنجة', country: 'المغرب', countryCode: 'MA', latitude: 35.7595, longitude: -5.8340, timeZone: 'Africa/Casablanca'),
  City(id: 'ma-agadir', name: 'أغادير', country: 'المغرب', countryCode: 'MA', latitude: 30.4278, longitude: -9.5981, timeZone: 'Africa/Casablanca'),
  City(id: 'ma-meknes', name: 'مكناس', country: 'المغرب', countryCode: 'MA', latitude: 33.8935, longitude: -5.5473, timeZone: 'Africa/Casablanca'),
  City(id: 'ma-oujda', name: 'وجدة', country: 'المغرب', countryCode: 'MA', latitude: 34.6867, longitude: -1.9114, timeZone: 'Africa/Casablanca'),
  City(id: 'mr-nouakchott', name: 'نواكشوط', country: 'موريتانيا', countryCode: 'MR', latitude: 18.0735, longitude: -15.9582, timeZone: 'Africa/Nouakchott'),

  // القرن الأفريقي وأفريقيا
  City(id: 'so-mogadishu', name: 'مقديشو', country: 'الصومال', countryCode: 'SO', latitude: 2.0469, longitude: 45.3182, timeZone: 'Africa/Mogadishu'),
  City(id: 'dj-djibouti', name: 'جيبوتي', country: 'جيبوتي', countryCode: 'DJ', latitude: 11.5721, longitude: 43.1456, timeZone: 'Africa/Djibouti'),
  City(id: 'km-moroni', name: 'موروني', country: 'جزر القمر', countryCode: 'KM', latitude: -11.7172, longitude: 43.2473, timeZone: 'Indian/Comoro'),
  City(id: 'et-addis', name: 'أديس أبابا', country: 'إثيوبيا', countryCode: 'ET', latitude: 9.0300, longitude: 38.7400, timeZone: 'Africa/Addis_Ababa'),
  City(id: 'ng-lagos', name: 'لاغوس', country: 'نيجيريا', countryCode: 'NG', latitude: 6.5244, longitude: 3.3792, timeZone: 'Africa/Lagos'),
  City(id: 'ng-kano', name: 'كانو', country: 'نيجيريا', countryCode: 'NG', latitude: 12.0022, longitude: 8.5920, timeZone: 'Africa/Lagos'),
  City(id: 'ng-abuja', name: 'أبوجا', country: 'نيجيريا', countryCode: 'NG', latitude: 9.0765, longitude: 7.3986, timeZone: 'Africa/Lagos'),
  City(id: 'sn-dakar', name: 'داكار', country: 'السنغال', countryCode: 'SN', latitude: 14.7167, longitude: -17.4677, timeZone: 'Africa/Dakar'),
  City(id: 'ke-nairobi', name: 'نيروبي', country: 'كينيا', countryCode: 'KE', latitude: -1.2921, longitude: 36.8219, timeZone: 'Africa/Nairobi'),
  City(id: 'tz-dar', name: 'دار السلام', country: 'تنزانيا', countryCode: 'TZ', latitude: -6.7924, longitude: 39.2083, timeZone: 'Africa/Dar_es_Salaam'),
  City(id: 'za-capetown', name: 'كيب تاون', country: 'جنوب أفريقيا', countryCode: 'ZA', latitude: -33.9249, longitude: 18.4241, timeZone: 'Africa/Johannesburg'),
  City(id: 'za-johannesburg', name: 'جوهانسبرغ', country: 'جنوب أفريقيا', countryCode: 'ZA', latitude: -26.2041, longitude: 28.0473, timeZone: 'Africa/Johannesburg'),

  // تركيا وإيران وآسيا الوسطى
  City(id: 'tr-istanbul', name: 'إسطنبول', country: 'تركيا', countryCode: 'TR', latitude: 41.0082, longitude: 28.9784, timeZone: 'Europe/Istanbul'),
  City(id: 'tr-ankara', name: 'أنقرة', country: 'تركيا', countryCode: 'TR', latitude: 39.9334, longitude: 32.8597, timeZone: 'Europe/Istanbul'),
  City(id: 'tr-izmir', name: 'إزمير', country: 'تركيا', countryCode: 'TR', latitude: 38.4237, longitude: 27.1428, timeZone: 'Europe/Istanbul'),
  City(id: 'tr-bursa', name: 'بورصة', country: 'تركيا', countryCode: 'TR', latitude: 40.1826, longitude: 29.0665, timeZone: 'Europe/Istanbul'),
  City(id: 'tr-antalya', name: 'أنطاليا', country: 'تركيا', countryCode: 'TR', latitude: 36.8969, longitude: 30.7133, timeZone: 'Europe/Istanbul'),
  City(id: 'tr-konya', name: 'قونية', country: 'تركيا', countryCode: 'TR', latitude: 37.8746, longitude: 32.4932, timeZone: 'Europe/Istanbul'),
  City(id: 'tr-gaziantep', name: 'غازي عنتاب', country: 'تركيا', countryCode: 'TR', latitude: 37.0662, longitude: 37.3833, timeZone: 'Europe/Istanbul'),
  City(id: 'ir-tehran', name: 'طهران', country: 'إيران', countryCode: 'IR', latitude: 35.6892, longitude: 51.3890, timeZone: 'Asia/Tehran'),
  City(id: 'ir-mashhad', name: 'مشهد', country: 'إيران', countryCode: 'IR', latitude: 36.2605, longitude: 59.6168, timeZone: 'Asia/Tehran'),
  City(id: 'ir-isfahan', name: 'أصفهان', country: 'إيران', countryCode: 'IR', latitude: 32.6539, longitude: 51.6660, timeZone: 'Asia/Tehran'),
  City(id: 'az-baku', name: 'باكو', country: 'أذربيجان', countryCode: 'AZ', latitude: 40.4093, longitude: 49.8671, timeZone: 'Asia/Baku'),
  City(id: 'uz-tashkent', name: 'طشقند', country: 'أوزبكستان', countryCode: 'UZ', latitude: 41.2995, longitude: 69.2401, timeZone: 'Asia/Tashkent'),
  City(id: 'kz-almaty', name: 'ألماتي', country: 'كازاخستان', countryCode: 'KZ', latitude: 43.2220, longitude: 76.8512, timeZone: 'Asia/Almaty'),
  City(id: 'af-kabul', name: 'كابل', country: 'أفغانستان', countryCode: 'AF', latitude: 34.5553, longitude: 69.2075, timeZone: 'Asia/Kabul'),

  // شبه القارة الهندية
  City(id: 'pk-karachi', name: 'كراتشي', country: 'باكستان', countryCode: 'PK', latitude: 24.8607, longitude: 67.0011, timeZone: 'Asia/Karachi'),
  City(id: 'pk-lahore', name: 'لاهور', country: 'باكستان', countryCode: 'PK', latitude: 31.5204, longitude: 74.3587, timeZone: 'Asia/Karachi'),
  City(id: 'pk-islamabad', name: 'إسلام آباد', country: 'باكستان', countryCode: 'PK', latitude: 33.6844, longitude: 73.0479, timeZone: 'Asia/Karachi'),
  City(id: 'pk-peshawar', name: 'بيشاور', country: 'باكستان', countryCode: 'PK', latitude: 34.0151, longitude: 71.5249, timeZone: 'Asia/Karachi'),
  City(id: 'pk-faisalabad', name: 'فيصل آباد', country: 'باكستان', countryCode: 'PK', latitude: 31.4187, longitude: 73.0791, timeZone: 'Asia/Karachi'),
  City(id: 'in-delhi', name: 'نيودلهي', country: 'الهند', countryCode: 'IN', latitude: 28.6139, longitude: 77.2090, timeZone: 'Asia/Kolkata'),
  City(id: 'in-mumbai', name: 'مومباي', country: 'الهند', countryCode: 'IN', latitude: 19.0760, longitude: 72.8777, timeZone: 'Asia/Kolkata'),
  City(id: 'in-hyderabad', name: 'حيدر آباد', country: 'الهند', countryCode: 'IN', latitude: 17.3850, longitude: 78.4867, timeZone: 'Asia/Kolkata'),
  City(id: 'in-kolkata', name: 'كولكاتا', country: 'الهند', countryCode: 'IN', latitude: 22.5726, longitude: 88.3639, timeZone: 'Asia/Kolkata'),
  City(id: 'in-bangalore', name: 'بنغالور', country: 'الهند', countryCode: 'IN', latitude: 12.9716, longitude: 77.5946, timeZone: 'Asia/Kolkata'),
  City(id: 'in-lucknow', name: 'لكناو', country: 'الهند', countryCode: 'IN', latitude: 26.8467, longitude: 80.9462, timeZone: 'Asia/Kolkata'),
  City(id: 'bd-dhaka', name: 'دكا', country: 'بنغلاديش', countryCode: 'BD', latitude: 23.8103, longitude: 90.4125, timeZone: 'Asia/Dhaka'),
  City(id: 'bd-chittagong', name: 'شيتاغونغ', country: 'بنغلاديش', countryCode: 'BD', latitude: 22.3569, longitude: 91.7832, timeZone: 'Asia/Dhaka'),

  // جنوب شرق آسيا
  City(id: 'id-jakarta', name: 'جاكرتا', country: 'إندونيسيا', countryCode: 'ID', latitude: -6.2088, longitude: 106.8456, timeZone: 'Asia/Jakarta'),
  City(id: 'id-surabaya', name: 'سورابايا', country: 'إندونيسيا', countryCode: 'ID', latitude: -7.2575, longitude: 112.7521, timeZone: 'Asia/Jakarta'),
  City(id: 'id-bandung', name: 'باندونغ', country: 'إندونيسيا', countryCode: 'ID', latitude: -6.9175, longitude: 107.6191, timeZone: 'Asia/Jakarta'),
  City(id: 'id-medan', name: 'ميدان', country: 'إندونيسيا', countryCode: 'ID', latitude: 3.5952, longitude: 98.6722, timeZone: 'Asia/Jakarta'),
  City(id: 'my-kualalumpur', name: 'كوالالمبور', country: 'ماليزيا', countryCode: 'MY', latitude: 3.1390, longitude: 101.6869, timeZone: 'Asia/Kuala_Lumpur'),
  City(id: 'my-johor', name: 'جوهور بهرو', country: 'ماليزيا', countryCode: 'MY', latitude: 1.4927, longitude: 103.7414, timeZone: 'Asia/Kuala_Lumpur'),
  City(id: 'my-penang', name: 'جورج تاون', country: 'ماليزيا', countryCode: 'MY', latitude: 5.4141, longitude: 100.3288, timeZone: 'Asia/Kuala_Lumpur'),
  City(id: 'bn-bandar', name: 'بندر سري بكاوان', country: 'بروناي', countryCode: 'BN', latitude: 4.9031, longitude: 114.9398, timeZone: 'Asia/Brunei'),
  City(id: 'sg-singapore', name: 'سنغافورة', country: 'سنغافورة', countryCode: 'SG', latitude: 1.3521, longitude: 103.8198, timeZone: 'Asia/Singapore'),

  // أوروبا
  City(id: 'gb-london', name: 'لندن', country: 'بريطانيا', countryCode: 'GB', latitude: 51.5074, longitude: -0.1278, timeZone: 'Europe/London'),
  City(id: 'gb-birmingham', name: 'برمنغهام', country: 'بريطانيا', countryCode: 'GB', latitude: 52.4862, longitude: -1.8904, timeZone: 'Europe/London'),
  City(id: 'gb-manchester', name: 'مانشستر', country: 'بريطانيا', countryCode: 'GB', latitude: 53.4808, longitude: -2.2426, timeZone: 'Europe/London'),
  City(id: 'gb-leeds', name: 'ليدز', country: 'بريطانيا', countryCode: 'GB', latitude: 53.8008, longitude: -1.5491, timeZone: 'Europe/London'),
  City(id: 'gb-glasgow', name: 'غلاسكو', country: 'بريطانيا', countryCode: 'GB', latitude: 55.8642, longitude: -4.2518, timeZone: 'Europe/London'),
  City(id: 'fr-paris', name: 'باريس', country: 'فرنسا', countryCode: 'FR', latitude: 48.8566, longitude: 2.3522, timeZone: 'Europe/Paris'),
  City(id: 'fr-marseille', name: 'مرسيليا', country: 'فرنسا', countryCode: 'FR', latitude: 43.2965, longitude: 5.3698, timeZone: 'Europe/Paris'),
  City(id: 'fr-lyon', name: 'ليون', country: 'فرنسا', countryCode: 'FR', latitude: 45.7640, longitude: 4.8357, timeZone: 'Europe/Paris'),
  City(id: 'fr-lille', name: 'ليل', country: 'فرنسا', countryCode: 'FR', latitude: 50.6292, longitude: 3.0573, timeZone: 'Europe/Paris'),
  City(id: 'de-berlin', name: 'برلين', country: 'ألمانيا', countryCode: 'DE', latitude: 52.5200, longitude: 13.4050, timeZone: 'Europe/Berlin'),
  City(id: 'de-hamburg', name: 'هامبورغ', country: 'ألمانيا', countryCode: 'DE', latitude: 53.5511, longitude: 9.9937, timeZone: 'Europe/Berlin'),
  City(id: 'de-munich', name: 'ميونخ', country: 'ألمانيا', countryCode: 'DE', latitude: 48.1351, longitude: 11.5820, timeZone: 'Europe/Berlin'),
  City(id: 'de-cologne', name: 'كولونيا', country: 'ألمانيا', countryCode: 'DE', latitude: 50.9375, longitude: 6.9603, timeZone: 'Europe/Berlin'),
  City(id: 'de-frankfurt', name: 'فرانكفورت', country: 'ألمانيا', countryCode: 'DE', latitude: 50.1109, longitude: 8.6821, timeZone: 'Europe/Berlin'),
  City(id: 'nl-amsterdam', name: 'أمستردام', country: 'هولندا', countryCode: 'NL', latitude: 52.3676, longitude: 4.9041, timeZone: 'Europe/Amsterdam'),
  City(id: 'nl-rotterdam', name: 'روتردام', country: 'هولندا', countryCode: 'NL', latitude: 51.9244, longitude: 4.4777, timeZone: 'Europe/Amsterdam'),
  City(id: 'nl-hague', name: 'لاهاي', country: 'هولندا', countryCode: 'NL', latitude: 52.0705, longitude: 4.3007, timeZone: 'Europe/Amsterdam'),
  City(id: 'be-brussels', name: 'بروكسل', country: 'بلجيكا', countryCode: 'BE', latitude: 50.8503, longitude: 4.3517, timeZone: 'Europe/Brussels'),
  City(id: 'be-antwerp', name: 'أنتويرب', country: 'بلجيكا', countryCode: 'BE', latitude: 51.2194, longitude: 4.4025, timeZone: 'Europe/Brussels'),
  City(id: 'se-stockholm', name: 'ستوكهولم', country: 'السويد', countryCode: 'SE', latitude: 59.3293, longitude: 18.0686, timeZone: 'Europe/Stockholm'),
  City(id: 'se-malmo', name: 'مالمو', country: 'السويد', countryCode: 'SE', latitude: 55.6050, longitude: 13.0038, timeZone: 'Europe/Stockholm'),
  City(id: 'se-gothenburg', name: 'غوتنبرغ', country: 'السويد', countryCode: 'SE', latitude: 57.7089, longitude: 11.9746, timeZone: 'Europe/Stockholm'),
  City(id: 'no-oslo', name: 'أوسلو', country: 'النرويج', countryCode: 'NO', latitude: 59.9139, longitude: 10.7522, timeZone: 'Europe/Oslo'),
  City(id: 'dk-copenhagen', name: 'كوبنهاغن', country: 'الدنمارك', countryCode: 'DK', latitude: 55.6761, longitude: 12.5683, timeZone: 'Europe/Copenhagen'),
  City(id: 'es-madrid', name: 'مدريد', country: 'إسبانيا', countryCode: 'ES', latitude: 40.4168, longitude: -3.7038, timeZone: 'Europe/Madrid'),
  City(id: 'es-barcelona', name: 'برشلونة', country: 'إسبانيا', countryCode: 'ES', latitude: 41.3874, longitude: 2.1686, timeZone: 'Europe/Madrid'),
  City(id: 'it-rome', name: 'روما', country: 'إيطاليا', countryCode: 'IT', latitude: 41.9028, longitude: 12.4964, timeZone: 'Europe/Rome'),
  City(id: 'it-milan', name: 'ميلانو', country: 'إيطاليا', countryCode: 'IT', latitude: 45.4642, longitude: 9.1900, timeZone: 'Europe/Rome'),
  City(id: 'at-vienna', name: 'فيينا', country: 'النمسا', countryCode: 'AT', latitude: 48.2082, longitude: 16.3738, timeZone: 'Europe/Vienna'),
  City(id: 'ch-zurich', name: 'زيورخ', country: 'سويسرا', countryCode: 'CH', latitude: 47.3769, longitude: 8.5417, timeZone: 'Europe/Zurich'),
  City(id: 'ch-geneva', name: 'جنيف', country: 'سويسرا', countryCode: 'CH', latitude: 46.2044, longitude: 6.1432, timeZone: 'Europe/Zurich'),
  City(id: 'ba-sarajevo', name: 'سراييفو', country: 'البوسنة والهرسك', countryCode: 'BA', latitude: 43.8563, longitude: 18.4131, timeZone: 'Europe/Sarajevo'),
  City(id: 'al-tirana', name: 'تيرانا', country: 'ألبانيا', countryCode: 'AL', latitude: 41.3275, longitude: 19.8187, timeZone: 'Europe/Tirane'),
  City(id: 'ru-moscow', name: 'موسكو', country: 'روسيا', countryCode: 'RU', latitude: 55.7558, longitude: 37.6173, timeZone: 'Europe/Moscow'),
  City(id: 'ru-kazan', name: 'قازان', country: 'روسيا', countryCode: 'RU', latitude: 55.8304, longitude: 49.0661, timeZone: 'Europe/Moscow'),

  // الأمريكتان وأستراليا
  City(id: 'us-newyork', name: 'نيويورك', country: 'الولايات المتحدة', countryCode: 'US', latitude: 40.7128, longitude: -74.0060, timeZone: 'America/New_York'),
  City(id: 'us-washington', name: 'واشنطن', country: 'الولايات المتحدة', countryCode: 'US', latitude: 38.9072, longitude: -77.0369, timeZone: 'America/New_York'),
  City(id: 'us-dearborn', name: 'ديربورن', country: 'الولايات المتحدة', countryCode: 'US', latitude: 42.3223, longitude: -83.1763, timeZone: 'America/Detroit'),
  City(id: 'us-atlanta', name: 'أتلانتا', country: 'الولايات المتحدة', countryCode: 'US', latitude: 33.7490, longitude: -84.3880, timeZone: 'America/New_York'),
  City(id: 'us-chicago', name: 'شيكاغو', country: 'الولايات المتحدة', countryCode: 'US', latitude: 41.8781, longitude: -87.6298, timeZone: 'America/Chicago'),
  City(id: 'us-houston', name: 'هيوستن', country: 'الولايات المتحدة', countryCode: 'US', latitude: 29.7604, longitude: -95.3698, timeZone: 'America/Chicago'),
  City(id: 'us-dallas', name: 'دالاس', country: 'الولايات المتحدة', countryCode: 'US', latitude: 32.7767, longitude: -96.7970, timeZone: 'America/Chicago'),
  City(id: 'us-minneapolis', name: 'مينيابوليس', country: 'الولايات المتحدة', countryCode: 'US', latitude: 44.9778, longitude: -93.2650, timeZone: 'America/Chicago'),
  City(id: 'us-losangeles', name: 'لوس أنجلوس', country: 'الولايات المتحدة', countryCode: 'US', latitude: 34.0522, longitude: -118.2437, timeZone: 'America/Los_Angeles'),
  City(id: 'us-seattle', name: 'سياتل', country: 'الولايات المتحدة', countryCode: 'US', latitude: 47.6062, longitude: -122.3321, timeZone: 'America/Los_Angeles'),
  City(id: 'ca-toronto', name: 'تورونتو', country: 'كندا', countryCode: 'CA', latitude: 43.6532, longitude: -79.3832, timeZone: 'America/Toronto'),
  City(id: 'ca-montreal', name: 'مونتريال', country: 'كندا', countryCode: 'CA', latitude: 45.5017, longitude: -73.5673, timeZone: 'America/Toronto'),
  City(id: 'ca-ottawa', name: 'أوتاوا', country: 'كندا', countryCode: 'CA', latitude: 45.4215, longitude: -75.6972, timeZone: 'America/Toronto'),
  City(id: 'ca-calgary', name: 'كالغاري', country: 'كندا', countryCode: 'CA', latitude: 51.0447, longitude: -114.0719, timeZone: 'America/Edmonton'),
  City(id: 'ca-vancouver', name: 'فانكوفر', country: 'كندا', countryCode: 'CA', latitude: 49.2827, longitude: -123.1207, timeZone: 'America/Vancouver'),
  City(id: 'br-saopaulo', name: 'ساو باولو', country: 'البرازيل', countryCode: 'BR', latitude: -23.5505, longitude: -46.6333, timeZone: 'America/Sao_Paulo'),
  City(id: 'au-sydney', name: 'سيدني', country: 'أستراليا', countryCode: 'AU', latitude: -33.8688, longitude: 151.2093, timeZone: 'Australia/Sydney'),
  City(id: 'au-melbourne', name: 'ملبورن', country: 'أستراليا', countryCode: 'AU', latitude: -37.8136, longitude: 144.9631, timeZone: 'Australia/Melbourne'),
  City(id: 'au-brisbane', name: 'بريزبن', country: 'أستراليا', countryCode: 'AU', latitude: -27.4698, longitude: 153.0251, timeZone: 'Australia/Brisbane'),
  City(id: 'au-perth', name: 'بيرث', country: 'أستراليا', countryCode: 'AU', latitude: -31.9505, longitude: 115.8605, timeZone: 'Australia/Perth'),
  City(id: 'nz-auckland', name: 'أوكلاند', country: 'نيوزيلندا', countryCode: 'NZ', latitude: -36.8485, longitude: 174.7633, timeZone: 'Pacific/Auckland'),
];

const City kDefaultCity = City(
  id: 'sa-makkah',
  name: 'مكة المكرمة',
  country: 'السعودية',
  countryCode: 'SA',
  latitude: 21.4225,
  longitude: 39.8262,
  timeZone: 'Asia/Riyadh',
);

const Map<String, CalculationMethod> _methodByCountry =
    <String, CalculationMethod>{
      'SA': CalculationMethod.umm_al_qura,
      'AE': CalculationMethod.dubai,
      'KW': CalculationMethod.kuwait,
      'QA': CalculationMethod.qatar,
      'BH': CalculationMethod.dubai,
      'OM': CalculationMethod.dubai,
      'YE': CalculationMethod.umm_al_qura,
      'EG': CalculationMethod.egyptian,
      'SD': CalculationMethod.egyptian,
      'LY': CalculationMethod.egyptian,
      'PS': CalculationMethod.egyptian,
      'JO': CalculationMethod.egyptian,
      'SY': CalculationMethod.egyptian,
      'LB': CalculationMethod.egyptian,
      'IQ': CalculationMethod.karachi,
      'TR': CalculationMethod.turkey,
      'IR': CalculationMethod.tehran,
      'PK': CalculationMethod.karachi,
      'IN': CalculationMethod.karachi,
      'BD': CalculationMethod.karachi,
      'AF': CalculationMethod.karachi,
      'SG': CalculationMethod.singapore,
      'MY': CalculationMethod.singapore,
      'ID': CalculationMethod.singapore,
      'BN': CalculationMethod.singapore,
      'US': CalculationMethod.north_america,
      'CA': CalculationMethod.north_america,
    };

CalculationMethod suggestedMethodFor(City city) {
  return _methodByCountry[city.countryCode] ??
      CalculationMethod.muslim_world_league;
}

City? cityById(String id) {
  for (final City city in kCities) {
    if (city.id == id) {
      return city;
    }
  }
  return null;
}

List<City> searchCities(String query) {
  final String needle = normalizeArabic(query);
  if (needle.isEmpty) {
    return kCities;
  }
  return kCities
      .where(
        (City city) =>
            normalizeArabic(city.name).contains(needle) ||
            normalizeArabic(city.country).contains(needle),
      )
      .toList(growable: false);
}

Map<String, List<City>> groupByCountry(List<City> cities) {
  final Map<String, List<City>> grouped = <String, List<City>>{};
  for (final City city in cities) {
    grouped.putIfAbsent(city.country, () => <City>[]).add(city);
  }
  return grouped;
}
