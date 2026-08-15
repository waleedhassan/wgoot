package apps.waleed.sunnah.wgoot.widget

import org.json.JSONArray
import org.json.JSONObject

data class WidgetSlot(
    val key: String,
    val title: String,
    val clock: String,
    val at: Long,
    val fard: Boolean,
)

data class WidgetDay(
    val startAt: Long,
    val endAt: Long,
    val weekday: String,
    val gregorian: String,
    val hijri: String,
    val slots: List<WidgetSlot>,
)

data class WidgetPayload(
    val city: String,
    val days: List<WidgetDay>,
) {
    fun dayAt(moment: Long): WidgetDay? =
        days.firstOrNull { moment >= it.startAt && moment < it.endAt }

    fun nextFard(moment: Long): WidgetSlot? =
        days.asSequence()
            .flatMap { it.slots.asSequence() }
            .firstOrNull { it.fard && it.at > moment }

    fun nextBoundary(moment: Long): Long? {
        val prayer = nextFard(moment)?.at?.plus(1_000L)
        val midnight = dayAt(moment)?.endAt
        return listOfNotNull(prayer, midnight).minOrNull()
    }

    companion object {
        fun parse(raw: String?): WidgetPayload? {
            if (raw.isNullOrBlank()) {
                return null
            }
            return runCatching {
                val root = JSONObject(raw)
                val days = root.optJSONArray("days") ?: return@runCatching null
                val parsed = (0 until days.length()).mapNotNull { index ->
                    days.optJSONObject(index)?.let(::parseDay)
                }
                if (parsed.isEmpty()) {
                    null
                } else {
                    WidgetPayload(city = root.optString("city"), days = parsed)
                }
            }.getOrNull()
        }

        private fun parseDay(json: JSONObject): WidgetDay? {
            val startAt = json.optLong("startAt", 0L)
            val endAt = json.optLong("endAt", 0L)
            if (startAt <= 0L || endAt <= startAt) {
                return null
            }
            return WidgetDay(
                startAt = startAt,
                endAt = endAt,
                weekday = json.optString("weekday"),
                gregorian = json.optString("gregorian"),
                hijri = json.optString("hijri"),
                slots = parseSlots(json.optJSONArray("slots")),
            )
        }

        private fun parseSlots(json: JSONArray?): List<WidgetSlot> {
            if (json == null) {
                return emptyList()
            }
            return (0 until json.length()).mapNotNull { index ->
                val slot = json.optJSONObject(index) ?: return@mapNotNull null
                val at = slot.optLong("at", 0L)
                if (at <= 0L) {
                    return@mapNotNull null
                }
                WidgetSlot(
                    key = slot.optString("key"),
                    title = slot.optString("title"),
                    clock = slot.optString("clock"),
                    at = at,
                    fard = slot.optBoolean("fard", true),
                )
            }
        }
    }
}
