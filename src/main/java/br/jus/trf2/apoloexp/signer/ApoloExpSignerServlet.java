package br.jus.trf2.apoloexp.signer;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import br.jus.trf2.assijus.system.api.IAssijusSystem;

import com.crivano.swaggerservlet.SwaggerServlet;
import com.crivano.swaggerservlet.SwaggerUtils;

public class ApoloExpSignerServlet extends SwaggerServlet {
	private static final long serialVersionUID = -1611417120964698257L;

	@Override
	public void init(ServletConfig config) throws ServletException {
		super.init(config);

		super.setAPI(IAssijusSystem.class);

		super.setActionPackage("br.jus.trf2.apoloexp.signer");

		super.setAuthorization(SwaggerUtils.getProperty("apoloexpsigner.password",
				null));
	}
}
