
package io.collapp.web.api;

import java.util.ArrayList;
import java.util.List;

abstract class Utils {

	/**
	 * CHECK:
	 *
	 * @param v
	 * @return
	 */
	static List<Integer> from(List<Number> v) {
		List<Integer> res = new ArrayList<>();
		for (Number n : v) {
			res.add(n.intValue());
		}
		return res;
	}
}
