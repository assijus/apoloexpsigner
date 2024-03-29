package br.jus.trf2.apoloexp.signer;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.sql.Blob;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.zip.DataFormatException;

import com.crivano.swaggerservlet.SwaggerServlet;

import br.jus.trf2.assijus.system.api.AssijusSystemContext;
import br.jus.trf2.assijus.system.api.IAssijusSystem.IDocIdPdfGet;

public class DocIdPdfGet implements IDocIdPdfGet {

	@Override
	public void run(Request req, Response resp, AssijusSystemContext ctx) throws Exception {
		String status = null;
		String error = null;
		final boolean fForcePKCS7 = true;

		Id id = new Id(req.id);

		// Produce responses
		resp.inputstream = new ByteArrayInputStream(getPdf(fForcePKCS7, id));
		SwaggerServlet.getHttpServletResponse().addHeader("Doc-Secret", getSecret(id));
	}

	private static byte[] getPdf(final boolean fForcePKCS7, Id id)
			throws SQLException, Exception, IOException, DataFormatException {
		byte[] pdf = null;
		String status;
		String error;
		// Chama a procedure que recupera os dados do PDF
		//
		Connection conn = null;
		CallableStatement cstmt = null;
		Exception exception = null;
		try {
			conn = Utils.getConnection();

			cstmt = conn.prepareCall(Utils.getSQL("pdfinfo"));

			// p_CodSecao -> Código da Seção Judiciária (50=ES; 51=RJ;
			// 2=TRF)
			cstmt.setInt(1, id.codsecao);

			// p_CodDoc -> Código interno do documento
			cstmt.setLong(2, id.coddoc);

			// CPF
			cstmt.setString(3, id.cpf);

			// Recuperar o PDF completo para permitir a assinatura sem política?
			cstmt.setInt(4, fForcePKCS7 ? 1 : 0);

			// SHA1
			cstmt.registerOutParameter(5, Types.VARCHAR);

			// SHA256
			cstmt.registerOutParameter(6, Types.VARCHAR);

			// Número de páginas
			cstmt.registerOutParameter(7, Types.NUMERIC);

			// Data hora da última atualização
			cstmt.registerOutParameter(8, Types.TIMESTAMP);

			// PDF uncompressed
			cstmt.registerOutParameter(9, Types.BLOB);

			// Status
			cstmt.registerOutParameter(10, Types.VARCHAR);

			// Error
			cstmt.registerOutParameter(11, Types.VARCHAR);

			cstmt.execute();

			// recupera o pdf para fazer assinatura sem política, apenas se ele
			// for diferente de null
			Blob blob = cstmt.getBlob(9);
			if (blob != null)
				pdf = blob.getBytes(1, (int) blob.length());
			status = cstmt.getString(10);
			error = cstmt.getString(11);
		} catch (Exception ex) {
			exception = ex;
			pdf = null;
		} finally {
			if (cstmt != null)
				cstmt.close();
			if (conn != null)
				conn.close();
		}

		if (pdf == null && ApoloExpSignerServlet.getProp("pdfservice.url") != null) {
			byte[] docCompressed = null;

			// Get documents from Oracle
			conn = null;
			PreparedStatement pstmt = null;
			ResultSet rset = null;
			try {
				conn = Utils.getConnection();
				pstmt = conn.prepareStatement(Utils.getSQL("doc"));
				pstmt.setLong(1, id.coddoc);
				pstmt.setInt(2, id.codsecao);
				rset = pstmt.executeQuery();

				if (rset.next()) {
					Blob blob = rset.getBlob("TXTWORD");
					docCompressed = blob.getBytes(1L, (int) blob.length());
				} else {
					throw new Exception("Nenhum DOC encontrado.");
				}

				if (rset.next())
					throw new Exception("Mais de um DOC encontrado.");
			} finally {
				if (rset != null)
					rset.close();
				if (pstmt != null)
					pstmt.close();
				if (conn != null)
					conn.close();
			}

			if (docCompressed == null)
				throw new Exception("Não foi possível localizar o DOC.");

			// Decompress
			byte[] doc = Utils.decompress(docCompressed);

			if (doc == null)
				throw new Exception("Não foi possível descomprimir o DOC.");

			// Convert
			pdf = Utils.convertDocToPdf(doc);
			// pdf = Utils.convertDocToPdfUnoConv(doc);

			if (pdf == null)
				throw new Exception("Não foi possível converter para PDF.");
		}

		if (pdf == null && exception != null)
			throw exception;

		return pdf;
	}

	public static String getSecret(Id id) throws Exception {
		// Get documents from Oracle
		Connection conn = null;
		PreparedStatement pstmt = null;
		ResultSet rset = null;
		try {
			conn = Utils.getConnection();
			pstmt = conn.prepareStatement(Utils.getSQL("secret"));
			pstmt.setLong(1, id.coddoc);
			pstmt.setInt(2, id.codsecao);
			rset = pstmt.executeQuery();

			if (rset.next()) {
				return rset.getString("secret");
			} else {
				throw new Exception("Nenhum DOC encontrado.");
			}
		} finally {
			if (rset != null)
				rset.close();
			if (pstmt != null)
				pstmt.close();
			if (conn != null)
				conn.close();
		}

	}

	@Override
	public String getContext() {
		return "visualizar documento";
	}
}
