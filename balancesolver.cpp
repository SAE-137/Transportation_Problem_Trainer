#include "balancesolver.h"


BalanceResult BalanceSolver::solve(const TransportProblemState& source) const
{
    BalanceResult result;

    result.costMatrix = source.costMatrix();
    result.supply = source.supply();
    result.demand = source.demand();

    for (int x : result.supply)
        result.sumSupply += x;

    for (int x : result.demand)
        result.sumDemand += x;

    if (result.sumSupply == result.sumDemand) {
        result.valid = true;
        result.alreadyBalanced = true;
        result.message =
            QString("Балансировка не нужна, потому что сумма запасов равна сумме потребностей: %1 = %2.")
                .arg(result.sumSupply)
                .arg(result.sumDemand);
        return result;
    }

    if (result.sumSupply > result.sumDemand) {
        const int diff = result.sumSupply - result.sumDemand;

        result.demand.push_back(diff);
        for (auto& row : result.costMatrix)
            row.push_back(0);

        result.valid = true;
        result.alreadyBalanced = false;
        result.message =
            QString("Балансировка нужна, потому что сумма запасов больше суммы потребностей: %1 > %2. "
                    "Добавлен фиктивный потребитель A%3 с потребностью %4 и нулевыми тарифами.")
                .arg(result.sumSupply)
                .arg(result.sumDemand)
                .arg(result.demand.size())
                .arg(diff);

        return result;
    }

    const int diff = result.sumDemand - result.sumSupply;

    result.supply.push_back(diff);

    QVector<int> newRow(result.demand.size(), 0);
    result.costMatrix.push_back(newRow);

    result.valid = true;
    result.alreadyBalanced = false;
    result.message =
        QString("Балансировка нужна, потому что сумма потребностей больше суммы запасов: %1 > %2. "
                "Добавлен фиктивный поставщик B%3 с запасом %4 и нулевыми тарифами.")
            .arg(result.sumDemand)
            .arg(result.sumSupply)
            .arg(result.supply.size())
            .arg(diff);

    return result;
}
