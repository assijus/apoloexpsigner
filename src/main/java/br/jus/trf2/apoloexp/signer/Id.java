package br.jus.trf2.apoloexp.signer;

import java.sql.Timestamp;

public class Id {
	String cpf;
	int codsecao;
	long coddoc;

	public Id(String id) {
		String[] split = id.split("_");
		this.cpf = split[0];
		this.codsecao = Integer.valueOf(split[1]);
		this.coddoc = Long.valueOf(split[2]);
	}

	public Id(String cpf, int codsecao, long coddoc) {
		this.cpf = cpf;
		this.codsecao = codsecao;
		this.coddoc = coddoc;
	}

	public String toString() {
		return cpf + "_" + codsecao + "_" + coddoc;
	}
}
